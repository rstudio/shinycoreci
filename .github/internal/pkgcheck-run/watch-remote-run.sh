#!/usr/bin/env bash
# Locate the workflow run we just dispatched in the target repo, then poll
# until it completes (or we hit watch_timeout). Emits run_id, run_url,
# run_conclusion, and should_open_issue to $GITHUB_OUTPUT.
#
# Required env (provided by the composite action's `env:` block):
#   GH_TOKEN, TARGET_OWNER, TARGET_REPO, TARGET_WORKFLOW, TARGET_REF,
#   DISPATCHED_AT, APP_SLUG,
#   LOOKUP_ATTEMPTS, LOOKUP_INTERVAL, WATCH_ATTEMPTS, WATCH_INTERVAL,
#   GITHUB_OUTPUT.

set -euo pipefail

# The App token's effective actor is "<app-slug>[bot]". Used to filter
# concurrent runs on the same workflow down to the one we dispatched.
bot_login=""
if [[ -n "${APP_SLUG}" ]]; then
  bot_login="${APP_SLUG}[bot]"
fi

run_id=""
for _ in $(seq 1 "${LOOKUP_ATTEMPTS}"); do
  response="$(gh api \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "/repos/${TARGET_OWNER}/${TARGET_REPO}/actions/workflows/${TARGET_WORKFLOW}/runs?event=workflow_dispatch&branch=${TARGET_REF}&per_page=20")"

  run_id="$(jq -r \
    --arg dispatched_at "${DISPATCHED_AT}" \
    --arg bot_login "${bot_login}" \
    '[
      .workflow_runs[]
      | select(.created_at >= $dispatched_at)
    ]
    | sort_by(.created_at)
    | (
        map(select(($bot_login != "") and ((.triggering_actor.login // .actor.login // "") == $bot_login)))
        | first
      ) // first
    | .id // empty' <<<"${response}")"

  [[ -n "${run_id}" ]] && break
  sleep "${LOOKUP_INTERVAL}"
done

if [[ -z "${run_id}" ]]; then
  echo "run_conclusion=dispatch_not_found" >> "$GITHUB_OUTPUT"
  echo "should_open_issue=true" >> "$GITHUB_OUTPUT"
  exit 0
fi

echo "run_id=${run_id}" >> "$GITHUB_OUTPUT"

for _ in $(seq 1 "${WATCH_ATTEMPTS}"); do
  run_json="$(gh api \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "/repos/${TARGET_OWNER}/${TARGET_REPO}/actions/runs/${run_id}")"

  status="$(jq -r '.status' <<<"${run_json}")"
  conclusion="$(jq -r '.conclusion // ""' <<<"${run_json}")"
  run_url="$(jq -r '.html_url' <<<"${run_json}")"
  echo "Remote status: ${status}${conclusion:+ (${conclusion})}"

  if [[ "${status}" == "completed" ]]; then
    echo "run_url=${run_url}" >> "$GITHUB_OUTPUT"
    echo "run_conclusion=${conclusion}" >> "$GITHUB_OUTPUT"
    case "${conclusion}" in
      failure|timed_out|action_required|startup_failure|stale)
        echo "should_open_issue=true" >> "$GITHUB_OUTPUT"
        ;;
      *)
        echo "should_open_issue=false" >> "$GITHUB_OUTPUT"
        ;;
    esac
    exit 0
  fi

  sleep "${WATCH_INTERVAL}"
done

echo "run_url=https://github.com/${TARGET_OWNER}/${TARGET_REPO}/actions/runs/${run_id}" >> "$GITHUB_OUTPUT"
echo "run_conclusion=watch_timeout" >> "$GITHUB_OUTPUT"
echo "should_open_issue=true" >> "$GITHUB_OUTPUT"

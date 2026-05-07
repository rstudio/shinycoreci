#!/usr/bin/env bash
# Dispatch the target workflow on the PR branch and watch for the resulting run.
# Writes `conclusion`, `run_url`, `run_id`, and `attempt` to $GITHUB_OUTPUT.
# Also writes the run log to .shinycoreci-remediation/remote-run.log so a follow-up
# Claude attempt can read it.
#
# Required env vars:
#   TARGET_GH_TOKEN  GitHub App token for the target repo.
#   TARGET_OWNER     Target repo owner.
#   TARGET_REPO      Target repo name.
#   TARGET_WORKFLOW  Workflow file (e.g. R-CMD-check.yaml) to dispatch.
#   PR_BRANCH        Branch (head of the remediation PR) to dispatch on.
#   APP_SLUG         GitHub App slug used to filter the matching run.
#   LOOKUP_ATTEMPTS  Polls until the dispatched run appears.
#   LOOKUP_INTERVAL  Seconds between lookup polls.
#   WATCH_ATTEMPTS   Polls until the dispatched run completes.
#   WATCH_INTERVAL   Seconds between watch polls.
#
# Args:
#   $1  Attempt number (1 or 2), echoed back as the `attempt` output.

set -euo pipefail

attempt="${1:-1}"

dispatched_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

echo "Dispatching ${TARGET_OWNER}/${TARGET_REPO} ${TARGET_WORKFLOW} on PR branch ${PR_BRANCH} (verification attempt ${attempt})."

GH_TOKEN="${TARGET_GH_TOKEN}" gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/repos/${TARGET_OWNER}/${TARGET_REPO}/actions/workflows/${TARGET_WORKFLOW}/dispatches" \
  --input - <<<"$(jq -n --arg ref "${PR_BRANCH}" '{ref: $ref}')"

bot_login=""
[[ -n "${APP_SLUG:-}" ]] && bot_login="${APP_SLUG}[bot]"

run_id=""
for _ in $(seq 1 "${LOOKUP_ATTEMPTS}"); do
  response="$(GH_TOKEN="${TARGET_GH_TOKEN}" gh api \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "/repos/${TARGET_OWNER}/${TARGET_REPO}/actions/workflows/${TARGET_WORKFLOW}/runs?event=workflow_dispatch&branch=${PR_BRANCH}&per_page=20")"

  run_id="$(jq -r \
    --arg dispatched_at "${dispatched_at}" \
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
  {
    echo "conclusion=dispatch_not_found"
    echo "run_url="
    echo "run_id="
    echo "attempt=${attempt}"
  } >> "$GITHUB_OUTPUT"
  exit 0
fi

conclusion=""
run_url=""
for _ in $(seq 1 "${WATCH_ATTEMPTS}"); do
  run_json="$(GH_TOKEN="${TARGET_GH_TOKEN}" gh api \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "/repos/${TARGET_OWNER}/${TARGET_REPO}/actions/runs/${run_id}")"

  status="$(jq -r '.status' <<<"${run_json}")"
  conclusion="$(jq -r '.conclusion // ""' <<<"${run_json}")"
  run_url="$(jq -r '.html_url' <<<"${run_json}")"
  echo "Verification status: ${status}${conclusion:+ (${conclusion})}"

  if [[ "${status}" == "completed" ]]; then
    break
  fi
  sleep "${WATCH_INTERVAL}"
done

if [[ -z "${conclusion}" ]]; then
  conclusion="watch_timeout"
  run_url="${run_url:-https://github.com/${TARGET_OWNER}/${TARGET_REPO}/actions/runs/${run_id}}"
fi

# Stash the run log for the next Claude attempt to inspect.
mkdir -p .shinycoreci-remediation
echo ".shinycoreci-remediation/" >> .git/info/exclude 2>/dev/null || true
log_file=".shinycoreci-remediation/remote-run.log"
if ! GH_TOKEN="${TARGET_GH_TOKEN}" gh run view "${run_id}" --repo "${TARGET_OWNER}/${TARGET_REPO}" --log > "${log_file}" 2>/dev/null; then
  {
    echo "Could not download logs for verification run ${run_id}."
    echo "Verification run URL: ${run_url}"
  } > "${log_file}"
fi

{
  echo "conclusion=${conclusion}"
  echo "run_url=${run_url}"
  echo "run_id=${run_id}"
  echo "attempt=${attempt}"
} >> "$GITHUB_OUTPUT"

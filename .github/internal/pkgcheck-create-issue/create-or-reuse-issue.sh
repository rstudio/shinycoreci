#!/usr/bin/env bash
# Create or reuse a remediation issue for a failing remote workflow run.
# Ensures any requested labels exist in the target repo before opening.
#
# Required env (provided by the composite action's `env:` block):
#   APP_GH_TOKEN, SOURCE_REPOSITORY, SOURCE_RUN_URL,
#   TARGET_OWNER, TARGET_REPO, TARGET_REF, TARGET_WORKFLOW, TARGET_MAINTAINER,
#   REMOTE_RUN_CONCLUSION, REMOTE_RUN_URL,
#   INPUT_ISSUE_TITLE, INPUT_CUSTOM_INSTRUCTIONS, INPUT_ISSUE_LABELS,
#   GITHUB_OUTPUT.

set -euo pipefail

create_issue() {
  local payload="$1"

  GH_TOKEN="${APP_GH_TOKEN}" gh api \
    --method POST \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "/repos/${TARGET_OWNER}/${TARGET_REPO}/issues" \
    --input - <<<"${payload}" 2>&1
}

write_issue_outputs() {
  local issue_json="$1"
  local issue_mode="$2"
  local existing_pr_url="${3:-}"

  issue_url="$(jq -r '.html_url' <<<"${issue_json}")"
  issue_number="$(jq -r '.number' <<<"${issue_json}")"

  echo "issue_url=${issue_url}" >> "$GITHUB_OUTPUT"
  echo "issue_number=${issue_number}" >> "$GITHUB_OUTPUT"
  echo "issue_mode=${issue_mode}" >> "$GITHUB_OUTPUT"
  echo "existing_pr_url=${existing_pr_url}" >> "$GITHUB_OUTPUT"
}

find_open_linked_pr() {
  local issue_number="$1"

  GH_TOKEN="${APP_GH_TOKEN}" gh api graphql \
    -f query='query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){issue(number:$number){timelineItems(first:100,itemTypes:[CROSS_REFERENCED_EVENT]){nodes{__typename ... on CrossReferencedEvent{source{__typename ... on PullRequest{url state isDraft}}}}}}}}' \
    -F owner="${TARGET_OWNER}" -F repo="${TARGET_REPO}" -F number="${issue_number}" \
    --jq '[.data.repository.issue.timelineItems.nodes[].source | select(.__typename=="PullRequest" and .state=="OPEN") | .url] | first // empty' 2>/dev/null || true
}

reuse_issue() {
  local issue_json="$1"
  local existing_issue_number
  existing_issue_number="$(jq -r '.number' <<<"${issue_json}")"
  local existing_pr_url
  existing_pr_url="$(find_open_linked_pr "${existing_issue_number}")"

  write_issue_outputs "${issue_json}" "existing" "${existing_pr_url}"
  echo "Open remediation issue already exists: ${issue_url}"
  if [[ -n "${existing_pr_url}" ]]; then
    echo "Open remediation PR already linked: ${existing_pr_url}"
  fi
  exit 0
}

if [[ -n "${INPUT_ISSUE_TITLE}" ]]; then
  title="${INPUT_ISSUE_TITLE}"
else
  title="Automated fix: ${TARGET_REPO} package checks failing on ${TARGET_REF}"
fi

# Parse the comma-separated label list into a clean JSON array, then
# ensure each label exists in the target repository so the issue
# creation call below does not fail with "label does not exist".
labels_json="$(jq -nc \
  --arg raw "${INPUT_ISSUE_LABELS}" \
  '[$raw | split(",") | .[] | gsub("^\\s+|\\s+$"; "") | select(length > 0)] | unique')"

ensure_label_exists() {
  local label="$1"

  if GH_TOKEN="${APP_GH_TOKEN}" gh api \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "/repos/${TARGET_OWNER}/${TARGET_REPO}/labels/$(jq -rn --arg s "${label}" '$s|@uri')" \
      >/dev/null 2>&1; then
    return 0
  fi

  local payload
  payload="$(jq -n \
    --arg name "${label}" \
    --arg color "ededed" \
    --arg description "Automatically opened by shinycoreci scheduler with AI assistance." \
    '{name: $name, color: $color, description: $description}')"

  GH_TOKEN="${APP_GH_TOKEN}" gh api \
    --method POST \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "/repos/${TARGET_OWNER}/${TARGET_REPO}/labels" \
    --input - <<<"${payload}" >/dev/null 2>&1 || true
}

while IFS= read -r label; do
  [[ -n "${label}" ]] && ensure_label_exists "${label}"
done < <(jq -r '.[]' <<<"${labels_json}")

remediation_marker="shinycoreci-remediation: ${TARGET_OWNER}/${TARGET_REPO}:${TARGET_WORKFLOW}:${TARGET_REF}"

find_existing_issue() {
  GH_TOKEN="${APP_GH_TOKEN}" gh api --paginate \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "/repos/${TARGET_OWNER}/${TARGET_REPO}/issues?state=open&per_page=100" \
    | jq -s -c -r \
      --arg title "${title}" \
      --arg marker "${remediation_marker}" \
      '[
        .[][]
        | select(.pull_request | not)
        | select((.title == $title) or ((.body // "") | contains($marker)))
      ]
      | sort_by(.created_at)
      | first // empty'
}

existing_issue_json="$(find_existing_issue || true)"

if [[ -n "${existing_issue_json}" ]]; then
  reuse_issue "${existing_issue_json}"
fi

body_lines=(
  "<!-- ${remediation_marker} -->"
  ""
  "> [!NOTE]"
  "> This issue was opened automatically by the \`${SOURCE_REPOSITORY}\` scheduler. An AI-assisted solver may attempt a fix; review carefully before merging."
  ""
  "## Summary"
  ""
  "The scheduled package checks triggered from \`${SOURCE_REPOSITORY}\` failed for \`${TARGET_OWNER}/${TARGET_REPO}\` on \`${TARGET_REF}\`."
  ""
  "## Failure details"
  ""
  "| Field | Value |"
  "| --- | --- |"
  "| Target repository | \`${TARGET_OWNER}/${TARGET_REPO}\` |"
  "| Target ref | \`${TARGET_REF}\` |"
  "| Remote workflow | \`${TARGET_WORKFLOW}\` |"
  "| Remote conclusion | \`${REMOTE_RUN_CONCLUSION}\` |"
  "| Remote run | ${REMOTE_RUN_URL:-not available} |"
  "| Source scheduler | \`${SOURCE_REPOSITORY}\` |"
  "| Scheduler run | ${SOURCE_RUN_URL} |"
  "| Suggested maintainer | @${TARGET_MAINTAINER} |"
)

if [[ -n "${INPUT_CUSTOM_INSTRUCTIONS}" ]]; then
  body_lines+=(
    ""
    "## Additional instructions"
    ""
    "${INPUT_CUSTOM_INSTRUCTIONS}"
  )
fi

printf -v issue_body '%s\n' "${body_lines[@]}"
issue_body="${issue_body%$'\n'}"

payload="$(jq -n \
  --arg title "${title}" \
  --arg body "${issue_body}" \
  --arg maintainer "${TARGET_MAINTAINER}" \
  --argjson labels "${labels_json}" \
  '{
    title: $title,
    body: $body,
    assignees: [$maintainer],
    labels: $labels
  }')"

set +e
issue_response="$(create_issue "${payload}")"
status=$?
set -e

if [[ ${status} -ne 0 ]]; then
  existing_issue_json="$(find_existing_issue || true)"
  if [[ -n "${existing_issue_json}" ]]; then
    reuse_issue "${existing_issue_json}"
  fi

  echo "::error::Failed to create remediation issue."
  echo "${issue_response}"
  exit ${status}
fi

write_issue_outputs "${issue_response}" "created"
echo "Created remediation issue (created): ${issue_url}"

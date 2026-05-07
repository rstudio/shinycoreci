#!/usr/bin/env bash
# Post a final status summary to both the remediation issue and the PR after
# the verification attempts have completed (or after attempt 1 if the retry
# was skipped).
#
# Required env (provided by the composite action's `env:` block):
#   TARGET_GH_TOKEN, TARGET_OWNER, TARGET_REPO,
#   ISSUE_URL, PR_URL,
#   ATTEMPT_1_CONCLUSION, ATTEMPT_1_RUN_URL,
#   ATTEMPT_2_CONCLUSION, ATTEMPT_2_RUN_URL.

set -euo pipefail

[[ -z "${ATTEMPT_1_CONCLUSION}" ]] && exit 0

final_conclusion="${ATTEMPT_2_CONCLUSION:-${ATTEMPT_1_CONCLUSION}}"
attempts_used=1
[[ -n "${ATTEMPT_2_CONCLUSION}" ]] && attempts_used=2

if [[ "${final_conclusion}" == "success" ]]; then
  status_line="Verification succeeded after ${attempts_used} attempt(s)."
else
  status_line="Verification still failing after ${attempts_used} attempt(s) (final conclusion: \`${final_conclusion}\`). Manual review required."
fi

if [[ -n "${ATTEMPT_2_CONCLUSION}" ]]; then
  attempt_2_line="- Attempt 2 conclusion: \`${ATTEMPT_2_CONCLUSION}\` (${ATTEMPT_2_RUN_URL:-no run url})"
else
  attempt_2_line="- Attempt 2: not run"
fi

body="$(printf '%s\n' \
  "${status_line}" \
  "" \
  "- PR: ${PR_URL}" \
  "- Attempt 1 conclusion: \`${ATTEMPT_1_CONCLUSION}\` (${ATTEMPT_1_RUN_URL:-no run url})" \
  "${attempt_2_line}")"

issue_number="${ISSUE_URL##*/}"
GH_TOKEN="${TARGET_GH_TOKEN}" gh issue comment "${issue_number}" \
  --repo "${TARGET_OWNER}/${TARGET_REPO}" \
  --body "${body}" || true

pr_number="${PR_URL##*/}"
GH_TOKEN="${TARGET_GH_TOKEN}" gh pr comment "${pr_number}" \
  --repo "${TARGET_OWNER}/${TARGET_REPO}" \
  --body "${body}" || true

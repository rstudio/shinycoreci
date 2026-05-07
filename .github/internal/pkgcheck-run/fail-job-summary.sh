#!/usr/bin/env bash
# Emit ::error:: annotations and a step summary describing the remote failure
# and any issue / PR that was created, then exit 1 to fail the job.
#
# Required env (provided by the composite action's `env:` block):
#   TARGET_OWNER, TARGET_REPO,
#   REMOTE_RUN_CONCLUSION, REMOTE_RUN_URL,
#   ISSUE_URL, ISSUE_MODE, REMEDIATION_PR_URL,
#   GITHUB_STEP_SUMMARY.

set -euo pipefail

echo "::error::Remote package checks for ${TARGET_OWNER}/${TARGET_REPO} did not succeed (${REMOTE_RUN_CONCLUSION:-unknown})."
[[ -n "${REMOTE_RUN_URL}" ]] && echo "::error::Remote run: ${REMOTE_RUN_URL}"
[[ -n "${ISSUE_URL}" ]] && echo "::error::Remediation issue (${ISSUE_MODE:-unknown}): ${ISSUE_URL}"
[[ -n "${REMEDIATION_PR_URL}" ]] && echo "::error::Remediation PR: ${REMEDIATION_PR_URL}"

{
  echo "## ${TARGET_OWNER}/${TARGET_REPO} handoff"
  echo ""
  echo "- Remote conclusion: ${REMOTE_RUN_CONCLUSION:-unknown}"
  [[ -n "${REMOTE_RUN_URL}" ]] && echo "- Remote run: ${REMOTE_RUN_URL}"
  if [[ -n "${ISSUE_URL}" ]]; then
    echo "- Remediation issue (${ISSUE_MODE:-unknown}): ${ISSUE_URL}"
  else
    echo "- Remediation issue: not created"
  fi
  if [[ -n "${REMEDIATION_PR_URL}" ]]; then
    echo "- Remediation PR: ${REMEDIATION_PR_URL}"
  else
    echo "- Remediation PR: not created"
  fi
} >> "$GITHUB_STEP_SUMMARY"

if [[ "${REMOTE_RUN_CONCLUSION}" == "dispatch_not_found" ]]; then
  echo "::error::The remote workflow dispatch succeeded, but no matching workflow run could be found to watch."
fi

exit 1

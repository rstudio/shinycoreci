#!/usr/bin/env bash
# Download the failed remote workflow run's log into .shinycoreci-remediation/.
#
# Required env (provided by the composite action's `env:` block):
#   TARGET_GH_TOKEN, TARGET_OWNER, TARGET_REPO,
#   REMOTE_RUN_ID, REMOTE_RUN_URL.

set -euo pipefail

mkdir -p .shinycoreci-remediation
echo ".shinycoreci-remediation/" >> .git/info/exclude

log_file=".shinycoreci-remediation/remote-run.log"
if [[ -n "${REMOTE_RUN_ID}" ]]; then
  if ! GH_TOKEN="${TARGET_GH_TOKEN}" gh run view "${REMOTE_RUN_ID}" --repo "${TARGET_OWNER}/${TARGET_REPO}" --log > "${log_file}"; then
    {
      echo "Could not download logs for remote run ${REMOTE_RUN_ID}."
      echo "Remote run URL: ${REMOTE_RUN_URL:-not available}"
    } > "${log_file}"
  fi
else
  {
    echo "No remote run ID was available."
    echo "Remote run URL: ${REMOTE_RUN_URL:-not available}"
  } > "${log_file}"
fi

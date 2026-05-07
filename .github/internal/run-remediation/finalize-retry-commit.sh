#!/usr/bin/env bash
# After Claude Code Action's retry attempt, commit and push the resulting
# changes onto the existing PR branch (squashing if Claude opened its own
# retry branch). Emits `pushed=true|false` to $GITHUB_OUTPUT.
#
# Required env (provided by the composite action's `env:` block):
#   TARGET_GH_TOKEN, TARGET_OWNER, TARGET_REPO, TARGET_REF, TARGET_WORKFLOW,
#   ISSUE_URL,
#   REMOTE_RUN_URL, REMOTE_RUN_CONCLUSION, SOURCE_RUN_URL,
#   PR_BRANCH, PR_URL, CLAUDE_BRANCH_NAME,
#   GITHUB_OUTPUT.

set -euo pipefail

git remote set-url origin "https://x-access-token:${TARGET_GH_TOKEN}@github.com/${TARGET_OWNER}/${TARGET_REPO}.git"
git config user.name "shinycoreci-bedrock[bot]"
git config user.email "shinycoreci-bedrock[bot]@users.noreply.github.com"

rm -rf .shinycoreci-remediation || true

pr_title="fix(ci): follow-up remediation for ${TARGET_REPO} package checks"
commit_body="$(printf '%s\n' \
  "Automated remediation (second attempt)" \
  "" \
  "Refs: ${ISSUE_URL}" \
  "PR: ${PR_URL}" \
  "Previous verification conclusion: ${REMOTE_RUN_CONCLUSION}" \
  "Previous verification run: ${REMOTE_RUN_URL:-not available}" \
  "Scheduler run: ${SOURCE_RUN_URL}")"

retry_branch="${CLAUDE_BRANCH_NAME:-}"
current_branch="$(git branch --show-current || true)"
[[ -z "${retry_branch}" ]] && retry_branch="${current_branch}"

git add -A
if ! git diff --cached --quiet; then
  git commit -m "${pr_title}" -m "${commit_body}"
fi

retry_ref="$(git rev-parse HEAD)"
git fetch origin "${PR_BRANCH}:refs/remotes/origin/${PR_BRANCH}" --depth=50

if [[ -z "${retry_branch}" || "${retry_branch}" == "${PR_BRANCH}" || "${current_branch}" == "${PR_BRANCH}" ]]; then
  ahead_count="$(git rev-list --count "origin/${PR_BRANCH}..HEAD" 2>/dev/null || echo 0)"
  if [[ "${ahead_count}" != "0" ]]; then
    git push origin "HEAD:${PR_BRANCH}"
    echo "pushed=true" >> "$GITHUB_OUTPUT"
  else
    echo "pushed=false" >> "$GITHUB_OUTPUT"
  fi
  exit 0
fi

# Squash retry branch into the PR branch with a single conventional commit.
git fetch origin "${retry_branch}:refs/remotes/origin/${retry_branch}" --depth=50 || true
git switch "${PR_BRANCH}" 2>/dev/null || git switch -c "${PR_BRANCH}" "origin/${PR_BRANCH}"
git reset --hard "origin/${PR_BRANCH}"

if ! git merge --squash "${retry_ref}" 2>/dev/null && \
   ! git merge --squash "${retry_branch}" 2>/dev/null && \
   ! git merge --squash "origin/${retry_branch}" 2>/dev/null; then
  echo "::warning::Retry branch ${retry_branch} could not be squashed onto ${PR_BRANCH}; skipping."
  echo "pushed=false" >> "$GITHUB_OUTPUT"
  exit 0
fi

if git diff --cached --quiet; then
  echo "pushed=false" >> "$GITHUB_OUTPUT"
  exit 0
fi

git commit -m "${pr_title}" -m "${commit_body}"
git push origin "HEAD:${PR_BRANCH}"

# Try to delete the throwaway retry branch (best effort).
GH_TOKEN="${TARGET_GH_TOKEN}" gh api \
  --method DELETE \
  -H "Accept: application/vnd.github+json" \
  "/repos/${TARGET_OWNER}/${TARGET_REPO}/git/refs/heads/${retry_branch}" >/dev/null 2>&1 || true

echo "pushed=true" >> "$GITHUB_OUTPUT"

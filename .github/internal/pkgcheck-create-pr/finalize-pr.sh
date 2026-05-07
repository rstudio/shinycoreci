#!/usr/bin/env bash
# Commit, push, and open (or update) the remediation pull request after the
# Claude Code Action step has produced changes in the target repo's checkout.
# Emits pr_url, pr_number, and branch to $GITHUB_OUTPUT.
#
# Required env (provided by the composite action's `env:` block):
#   TARGET_GH_TOKEN, TARGET_OWNER, TARGET_REPO, TARGET_WORKFLOW, TARGET_REF,
#   TARGET_MAINTAINER, ISSUE_URL,
#   REMOTE_RUN_URL, REMOTE_RUN_CONCLUSION,
#   SOURCE_REPOSITORY, SOURCE_RUN_URL,
#   CLAUDE_BRANCH_NAME, GITHUB_OUTPUT,
#   GITHUB_RUN_ID, GITHUB_RUN_ATTEMPT.

set -euo pipefail

git remote set-url origin "https://x-access-token:${TARGET_GH_TOKEN}@github.com/${TARGET_OWNER}/${TARGET_REPO}.git"
git config user.name "shinycoreci-bedrock[bot]"
git config user.email "shinycoreci-bedrock[bot]@users.noreply.github.com"
git fetch origin "${TARGET_REF}:refs/remotes/origin/${TARGET_REF}" --depth=1

rm -rf .shinycoreci-remediation

status="$(git status --porcelain --untracked-files=all)"
current_branch="$(git branch --show-current || true)"
branch="${CLAUDE_BRANCH_NAME:-${current_branch}}"

if [[ -z "${branch}" || "${branch}" == "HEAD" || "${branch}" == "${TARGET_REF}" ]]; then
  safe_workflow="$(tr -c '[:alnum:]_.-' '-' <<<"${TARGET_WORKFLOW}" | sed -E 's/-+/-/g; s/^-//; s/-$//')"
  branch="shinycoreci/bedrock-remediation-${GITHUB_RUN_ID:-manual}-${GITHUB_RUN_ATTEMPT:-1}-${safe_workflow}"
  git switch -c "${branch}"
elif [[ "${current_branch}" != "${branch}" ]]; then
  if git show-ref --verify --quiet "refs/heads/${branch}"; then
    git switch "${branch}"
  else
    git switch -c "${branch}"
  fi
fi

if [[ -n "${status}" ]]; then
  git add -A
  pr_title="fix(ci): remediate ${TARGET_REPO} package checks on ${TARGET_REF}"
  commit_body="$(printf '%s\n' \
    "Automated remediation" \
    "" \
    "Refs: ${ISSUE_URL}" \
    "Remote workflow: ${TARGET_WORKFLOW}" \
    "Remote conclusion: ${REMOTE_RUN_CONCLUSION}" \
    "Remote run: ${REMOTE_RUN_URL:-not available}" \
    "Scheduler run: ${SOURCE_RUN_URL}")"
  git commit -m "${pr_title}" -m "${commit_body}"
fi

ahead_count="$(git rev-list --count "origin/${TARGET_REF}..HEAD" 2>/dev/null || echo 0)"
if [[ "${ahead_count}" == "0" ]]; then
  issue_number="${ISSUE_URL##*/}"
  GH_TOKEN="${TARGET_GH_TOKEN}" gh issue comment "${issue_number}" \
    --repo "${TARGET_OWNER}/${TARGET_REPO}" \
    --body "Automated remediation did not produce any file changes" || true
  echo "pr_url=" >> "$GITHUB_OUTPUT"
  echo "pr_number=" >> "$GITHUB_OUTPUT"
  exit 0
fi

git push --set-upstream origin "${branch}"

issue_number="${ISSUE_URL##*/}"
pr_url="$(GH_TOKEN="${TARGET_GH_TOKEN}" gh pr list \
  --repo "${TARGET_OWNER}/${TARGET_REPO}" \
  --head "${branch}" \
  --state open \
  --json url \
  --jq '.[0].url // empty')"

if [[ -z "${pr_url}" ]]; then
  pr_title="fix(ci): remediate ${TARGET_REPO} package checks on ${TARGET_REF}"
  body_file="$(mktemp)"
  {
    echo "## Summary"
    echo ""
    echo "Automated remediation for the failed package checks dispatched by \`${SOURCE_REPOSITORY}\`."
    echo ""
    echo "## Failure context"
    echo ""
    echo "| Field | Value |"
    echo "| --- | --- |"
    echo "| Target ref | \`${TARGET_REF}\` |"
    echo "| Remote workflow | \`${TARGET_WORKFLOW}\` |"
    echo "| Remote conclusion | \`${REMOTE_RUN_CONCLUSION}\` |"
    echo "| Remote run | ${REMOTE_RUN_URL:-not available} |"
    echo "| Scheduler run | ${SOURCE_RUN_URL} |"
    echo ""
    echo "Closes #${issue_number}"
  } > "${body_file}"

  pr_url="$(GH_TOKEN="${TARGET_GH_TOKEN}" gh pr create \
    --repo "${TARGET_OWNER}/${TARGET_REPO}" \
    --base "${TARGET_REF}" \
    --head "${branch}" \
    --title "${pr_title}" \
    --body-file "${body_file}" \
    --reviewer "${TARGET_MAINTAINER}" \
    --assignee "${TARGET_MAINTAINER}")"
else
  pr_number="${pr_url##*/}"
  GH_TOKEN="${TARGET_GH_TOKEN}" gh api \
    --method POST \
    -H "Accept: application/vnd.github+json" \
    "/repos/${TARGET_OWNER}/${TARGET_REPO}/pulls/${pr_number}/requested_reviewers" \
    -f "reviewers[]=${TARGET_MAINTAINER}" >/dev/null 2>&1 || true
  GH_TOKEN="${TARGET_GH_TOKEN}" gh api \
    --method POST \
    -H "Accept: application/vnd.github+json" \
    "/repos/${TARGET_OWNER}/${TARGET_REPO}/issues/${pr_number}/assignees" \
    -f "assignees[]=${TARGET_MAINTAINER}" >/dev/null 2>&1 || true
fi

echo "pr_url=${pr_url}" >> "$GITHUB_OUTPUT"
echo "pr_number=${pr_url##*/}" >> "$GITHUB_OUTPUT"
echo "branch=${branch}" >> "$GITHUB_OUTPUT"
echo "Opened remediation PR: ${pr_url}"

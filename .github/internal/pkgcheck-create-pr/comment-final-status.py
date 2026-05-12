#!/usr/bin/env python3
"""Post a final status summary to both the remediation issue and the PR after
the verification attempts have completed (or after attempt 1 if the retry
was skipped).

Required env (provided by the composite action's `env:` block):
    TARGET_GH_TOKEN, TARGET_OWNER, TARGET_REPO,
    ISSUE_URL, PR_URL,
    ATTEMPT_1_CONCLUSION, ATTEMPT_1_RUN_URL,
    ATTEMPT_2_CONCLUSION, ATTEMPT_2_RUN_URL.
"""
from __future__ import annotations

import os
import subprocess
import sys


def env(name: str, default: str = "") -> str:
    return os.environ.get(name, default)


def build_issue_body(pr_url: str, a1: str, a1_run: str, a2: str) -> str:
    final = a2 or a1
    attempts = 2 if a2 else 1

    if final == "success":
        status_line = (
            "Verification succeeded after the remediation PR was created and "
            f"the PR branch was rechecked {attempts} time(s)."
        )
    else:
        status_line = (
            "Verification still failing after the remediation PR was created "
            f"and rechecked {attempts} time(s) (final conclusion: `{final}`). "
            "Manual review required."
        )

    if a2:
        a2_run = env("ATTEMPT_2_RUN_URL") or "no run url"
        attempt_2_line = (
            "- Attempt 2: follow-up fix on the PR branch, then verification "
            f"run concluded `{a2}` ({a2_run})"
        )
    else:
        attempt_2_line = "- Attempt 2: not run"

    return "\n".join([
        status_line,
        "",
        f"- PR: {pr_url}",
        "- Attempt 1: initial remediation that created this PR, then "
        f"verification run concluded `{a1}` ({a1_run})",
        attempt_2_line,
    ])


def build_pr_body(issue_url: str, a1: str, a1_run: str, a2: str) -> str:
    final = a2 or a1
    attempts = 2 if a2 else 1

    if final == "success":
        status_line = (
            "Verification succeeded after the PR was created and the branch "
            f"was rechecked {attempts} time(s)."
        )
    else:
        status_line = (
            "Verification still failing after the PR was created and rechecked "
            f"{attempts} time(s) (final conclusion: `{final}`). Manual review "
            "required."
        )

    if a2:
        a2_run = env("ATTEMPT_2_RUN_URL") or "no run url"
        attempt_2_line = (
            "- Attempt 2: follow-up fix on this PR branch, then verification "
            f"run concluded `{a2}` ({a2_run})"
        )
    else:
        attempt_2_line = "- Attempt 2: not run"

    return "\n".join([
        status_line,
        "",
        f"- Issue: {issue_url}",
        "- Attempt 1: initial remediation that created this PR, then "
        f"verification run concluded `{a1}` ({a1_run})",
        attempt_2_line,
    ])


def main() -> int:
    a1 = env("ATTEMPT_1_CONCLUSION")
    if not a1:
        return 0

    a2 = env("ATTEMPT_2_CONCLUSION")
    a1_run = env("ATTEMPT_1_RUN_URL") or "no run url"
    pr_url = env("PR_URL")
    issue_url = env("ISSUE_URL")
    issue_body = build_issue_body(pr_url, a1, a1_run, a2)
    pr_body = build_pr_body(issue_url, a1, a1_run, a2)

    repo = f"{env('TARGET_OWNER')}/{env('TARGET_REPO')}"
    gh_env = {**os.environ, "GH_TOKEN": env("TARGET_GH_TOKEN")}
    issue_number = env("ISSUE_URL").rsplit("/", 1)[-1]
    pr_number = env("PR_URL").rsplit("/", 1)[-1]

    # Both comments are best-effort; failures shouldn't break the job.
    subprocess.run(
        [
            "gh", "issue", "comment", issue_number,
            "--repo", repo,
            "--body", issue_body,
        ],
        env=gh_env, check=False,
    )
    subprocess.run(
        [
            "gh", "pr", "comment", pr_number,
            "--repo", repo,
            "--body", pr_body,
        ],
        env=gh_env, check=False,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())

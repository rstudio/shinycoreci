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


def main() -> int:
    a1 = env("ATTEMPT_1_CONCLUSION")
    if not a1:
        return 0

    a2 = env("ATTEMPT_2_CONCLUSION")
    final = a2 or a1
    attempts = 2 if a2 else 1

    if final == "success":
        status_line = f"Verification succeeded after {attempts} attempt(s)."
    else:
        status_line = (
            f"Verification still failing after {attempts} attempt(s)"
            f" (final conclusion: `{final}`). Manual review required."
        )

    a1_run = env("ATTEMPT_1_RUN_URL") or "no run url"
    if a2:
        a2_run = env("ATTEMPT_2_RUN_URL") or "no run url"
        attempt_2_line = f"- Attempt 2 conclusion: `{a2}` ({a2_run})"
    else:
        attempt_2_line = "- Attempt 2: not run"

    body = "\n".join([
        status_line,
        "",
        f"- PR: {env('PR_URL')}",
        f"- Attempt 1 conclusion: `{a1}` ({a1_run})",
        attempt_2_line,
    ])

    repo = f"{env('TARGET_OWNER')}/{env('TARGET_REPO')}"
    gh_env = {**os.environ, "GH_TOKEN": env("TARGET_GH_TOKEN")}
    issue_number = env("ISSUE_URL").rsplit("/", 1)[-1]
    pr_number = env("PR_URL").rsplit("/", 1)[-1]

    # Both comments are best-effort; failures shouldn't break the job.
    subprocess.run(
        ["gh", "issue", "comment", issue_number, "--repo", repo, "--body", body],
        env=gh_env, check=False,
    )
    subprocess.run(
        ["gh", "pr", "comment", pr_number, "--repo", repo, "--body", body],
        env=gh_env, check=False,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())

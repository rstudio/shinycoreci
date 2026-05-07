#!/usr/bin/env python3
"""Emit ::error:: annotations and a step summary describing the remote failure
and any issue / PR that was created, then exit 1 to fail the job.

Required env (provided by the composite action's `env:` block):
    TARGET_OWNER, TARGET_REPO,
    REMOTE_RUN_CONCLUSION, REMOTE_RUN_URL,
    ISSUE_URL, ISSUE_MODE, REMEDIATION_PR_URL,
    GITHUB_STEP_SUMMARY.
"""
from __future__ import annotations

import os
import sys


def env(name: str, default: str = "") -> str:
    return os.environ.get(name, default)


def main() -> int:
    target = f"{env('TARGET_OWNER')}/{env('TARGET_REPO')}"
    conclusion = env("REMOTE_RUN_CONCLUSION") or "unknown"
    remote_url = env("REMOTE_RUN_URL")
    issue_url = env("ISSUE_URL")
    issue_mode = env("ISSUE_MODE") or "unknown"
    pr_url = env("REMEDIATION_PR_URL")

    print(f"::error::Remote package checks for {target} did not succeed ({conclusion}).")
    if remote_url:
        print(f"::error::Remote run: {remote_url}")
    if issue_url:
        print(f"::error::Remediation issue ({issue_mode}): {issue_url}")
    if pr_url:
        print(f"::error::Remediation PR: {pr_url}")

    summary_lines = [
        f"## {target} handoff",
        "",
        f"- Remote conclusion: {conclusion}",
    ]
    if remote_url:
        summary_lines.append(f"- Remote run: {remote_url}")
    summary_lines.append(
        f"- Remediation issue ({issue_mode}): {issue_url}" if issue_url
        else "- Remediation issue: not created"
    )
    summary_lines.append(
        f"- Remediation PR: {pr_url}" if pr_url
        else "- Remediation PR: not created"
    )

    with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as f:
        f.write("\n".join(summary_lines) + "\n")

    if env("REMOTE_RUN_CONCLUSION") == "dispatch_not_found":
        print("::error::The remote workflow dispatch succeeded, but no matching"
              " workflow run could be found to watch.")

    return 1


if __name__ == "__main__":
    sys.exit(main())

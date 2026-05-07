#!/usr/bin/env python3
"""After Claude Code Action's retry attempt, commit and push the resulting
changes onto the existing PR branch (squashing if Claude opened its own
retry branch). Emits `pushed=true|false` to $GITHUB_OUTPUT.

Required env (provided by the composite action's `env:` block):
    TARGET_GH_TOKEN, TARGET_OWNER, TARGET_REPO, TARGET_REF, TARGET_WORKFLOW,
    ISSUE_URL,
    REMOTE_RUN_URL, REMOTE_RUN_CONCLUSION, SOURCE_RUN_URL,
    PR_BRANCH, PR_URL, CLAUDE_BRANCH_NAME,
    GITHUB_OUTPUT.
"""
from __future__ import annotations

import os
import shutil
import subprocess
import sys


def env(name: str, default: str = "") -> str:
    return os.environ.get(name, default)


def gh_env() -> dict[str, str]:
    return {**os.environ, "GH_TOKEN": env("TARGET_GH_TOKEN")}


def git(*args: str, check: bool = True, capture: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args], check=check, text=True, capture_output=capture,
    )


def write_output(key: str, value: str) -> None:
    with open(os.environ["GITHUB_OUTPUT"], "a") as f:
        f.write(f"{key}={value}\n")


def has_staged_changes() -> bool:
    return git("diff", "--cached", "--quiet", check=False).returncode != 0


def main() -> int:
    repo = f"{env('TARGET_OWNER')}/{env('TARGET_REPO')}"
    pr_branch = env("PR_BRANCH")

    git("remote", "set-url", "origin",
        f"https://x-access-token:{env('TARGET_GH_TOKEN')}@github.com/{repo}.git")
    git("config", "user.name", "shinycoreci-bedrock[bot]")
    git("config", "user.email", "shinycoreci-bedrock[bot]@users.noreply.github.com")

    shutil.rmtree(".shinycoreci-remediation", ignore_errors=True)

    pr_title = f"fix(ci): follow-up remediation for {env('TARGET_REPO')} package checks"
    commit_body = "\n".join([
        "Automated remediation (second attempt)",
        "",
        f"Refs: {env('ISSUE_URL')}",
        f"PR: {env('PR_URL')}",
        f"Previous verification conclusion: {env('REMOTE_RUN_CONCLUSION')}",
        f"Previous verification run: {env('REMOTE_RUN_URL') or 'not available'}",
        f"Scheduler run: {env('SOURCE_RUN_URL')}",
    ])

    cur = git("branch", "--show-current", check=False).stdout.strip()
    retry_branch = env("CLAUDE_BRANCH_NAME") or cur

    git("add", "-A")
    if has_staged_changes():
        git("commit", "-m", pr_title, "-m", commit_body)

    retry_ref = git("rev-parse", "HEAD").stdout.strip()
    git("fetch", "origin", f"{pr_branch}:refs/remotes/origin/{pr_branch}", "--depth=50")

    # Fast path: we're already on the PR branch, just push if we're ahead.
    if not retry_branch or retry_branch == pr_branch or cur == pr_branch:
        ahead = git("rev-list", "--count", f"origin/{pr_branch}..HEAD",
                    check=False).stdout.strip() or "0"
        if ahead != "0":
            git("push", "origin", f"HEAD:{pr_branch}", capture=False)
            write_output("pushed", "true")
        else:
            write_output("pushed", "false")
        return 0

    # Slow path: Claude committed onto its own retry branch. Squash that work
    # into a single commit on top of the existing PR branch.
    git("fetch", "origin", f"{retry_branch}:refs/remotes/origin/{retry_branch}",
        "--depth=50", check=False)
    if git("switch", pr_branch, check=False).returncode != 0:
        git("switch", "-c", pr_branch, f"origin/{pr_branch}")
    git("reset", "--hard", f"origin/{pr_branch}")

    squashed = False
    for source in (retry_ref, retry_branch, f"origin/{retry_branch}"):
        if git("merge", "--squash", source, check=False).returncode == 0:
            squashed = True
            break

    if not squashed:
        print(f"::warning::Retry branch {retry_branch} could not be squashed onto"
              f" {pr_branch}; skipping.")
        write_output("pushed", "false")
        return 0

    if not has_staged_changes():
        write_output("pushed", "false")
        return 0

    git("commit", "-m", pr_title, "-m", commit_body)
    git("push", "origin", f"HEAD:{pr_branch}", capture=False)

    # Best-effort cleanup of the throwaway retry branch.
    subprocess.run(
        ["gh", "api", "--method", "DELETE",
         "-H", "Accept: application/vnd.github+json",
         f"/repos/{repo}/git/refs/heads/{retry_branch}"],
        env=gh_env(), capture_output=True, check=False,
    )

    write_output("pushed", "true")
    return 0


def _surface_subprocess_error(e: subprocess.CalledProcessError) -> int:
    """Print captured stdout/stderr from a failed subprocess so the Action log
    shows the underlying gh/git error instead of just a Python traceback."""
    cmd = " ".join(e.cmd) if isinstance(e.cmd, list) else str(e.cmd)
    print(f"::error::Command failed (exit {e.returncode}): {cmd}", file=sys.stderr)
    for payload in (e.stdout, e.stderr):
        if payload:
            sys.stderr.write(payload)
            if not payload.endswith("\n"):
                sys.stderr.write("\n")
    return e.returncode or 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except subprocess.CalledProcessError as e:
        sys.exit(_surface_subprocess_error(e))

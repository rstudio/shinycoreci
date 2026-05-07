#!/usr/bin/env python3
"""Commit, push, and open (or update) the remediation pull request after the
Claude Code Action step has produced changes in the target repo's checkout.
Emits pr_url, pr_number, and branch to $GITHUB_OUTPUT.

Required env (provided by the composite action's `env:` block):
    TARGET_GH_TOKEN, TARGET_OWNER, TARGET_REPO, TARGET_WORKFLOW, TARGET_REF,
    TARGET_MAINTAINER, ISSUE_URL,
    REMOTE_RUN_URL, REMOTE_RUN_CONCLUSION,
    SOURCE_REPOSITORY, SOURCE_RUN_URL,
    CLAUDE_BRANCH_NAME, GITHUB_OUTPUT,
    GITHUB_RUN_ID, GITHUB_RUN_ATTEMPT.
"""
from __future__ import annotations

import os
import re
import shutil
import subprocess
import sys
import tempfile


def env(name: str, default: str = "") -> str:
    return os.environ.get(name, default)


def gh_env() -> dict[str, str]:
    return {**os.environ, "GH_TOKEN": env("TARGET_GH_TOKEN")}


def git(*args: str, check: bool = True, capture: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        check=check,
        text=True,
        capture_output=capture,
    )


def write_output(key: str, value: str) -> None:
    with open(os.environ["GITHUB_OUTPUT"], "a") as f:
        f.write(f"{key}={value}\n")


def safe_workflow_slug(workflow: str) -> str:
    slug = re.sub(r"[^A-Za-z0-9_.-]", "-", workflow)
    return re.sub(r"-+", "-", slug).strip("-")


def current_branch() -> str:
    result = git("branch", "--show-current", check=False)
    return result.stdout.strip()


def comment(repo: str, issue_or_pr_number: str, body: str) -> None:
    subprocess.run(
        ["gh", "issue", "comment", issue_or_pr_number, "--repo", repo, "--body", body],
        env=gh_env(), check=False,
    )


def main() -> int:
    owner = env("TARGET_OWNER")
    repo_name = env("TARGET_REPO")
    repo = f"{owner}/{repo_name}"
    workflow = env("TARGET_WORKFLOW")
    target_ref = env("TARGET_REF")
    maintainer = env("TARGET_MAINTAINER")
    issue_url = env("ISSUE_URL")
    issue_number = issue_url.rsplit("/", 1)[-1]

    git("remote", "set-url", "origin",
        f"https://x-access-token:{env('TARGET_GH_TOKEN')}@github.com/{repo}.git")
    git("config", "user.name", "shinycoreci-bedrock[bot]")
    git("config", "user.email", "shinycoreci-bedrock[bot]@users.noreply.github.com")
    git("fetch", "origin", f"{target_ref}:refs/remotes/origin/{target_ref}", "--depth=1")

    shutil.rmtree(".shinycoreci-remediation", ignore_errors=True)

    status = git("status", "--porcelain", "--untracked-files=all").stdout
    cur = current_branch()
    branch = env("CLAUDE_BRANCH_NAME") or cur

    if not branch or branch == "HEAD" or branch == target_ref:
        slug = safe_workflow_slug(workflow)
        run_id = env("GITHUB_RUN_ID") or "manual"
        run_attempt = env("GITHUB_RUN_ATTEMPT") or "1"
        branch = f"shinycoreci/bedrock-remediation-{run_id}-{run_attempt}-{slug}"
        git("switch", "-c", branch)
    elif cur != branch:
        if git("show-ref", "--verify", "--quiet", f"refs/heads/{branch}",
               check=False).returncode == 0:
            git("switch", branch)
        else:
            git("switch", "-c", branch)

    pr_title = f"fix(ci): remediate {repo_name} package checks on {target_ref}"

    if status.strip():
        git("add", "-A")
        commit_body = "\n".join([
            "Automated remediation",
            "",
            f"Refs: {issue_url}",
            f"Remote workflow: {workflow}",
            f"Remote conclusion: {env('REMOTE_RUN_CONCLUSION')}",
            f"Remote run: {env('REMOTE_RUN_URL') or 'not available'}",
            f"Scheduler run: {env('SOURCE_RUN_URL')}",
        ])
        git("commit", "-m", pr_title, "-m", commit_body)

    ahead = git("rev-list", "--count", f"origin/{target_ref}..HEAD",
                check=False).stdout.strip() or "0"
    if ahead == "0":
        comment(repo, issue_number,
                "Automated remediation did not produce any file changes")
        write_output("pr_url", "")
        write_output("pr_number", "")
        return 0

    git("push", "--set-upstream", "origin", branch, capture=False)

    list_result = subprocess.run(
        ["gh", "pr", "list", "--repo", repo, "--head", branch,
         "--state", "open", "--json", "url", "--jq", ".[0].url // empty"],
        env=gh_env(), capture_output=True, text=True, check=True,
    )
    pr_url = list_result.stdout.strip()

    if not pr_url:
        body = "\n".join([
            "## Summary",
            "",
            f"Automated remediation for the failed package checks dispatched by"
            f" `{env('SOURCE_REPOSITORY')}`.",
            "",
            "## Failure context",
            "",
            "| Field | Value |",
            "| --- | --- |",
            f"| Target ref | `{target_ref}` |",
            f"| Remote workflow | `{workflow}` |",
            f"| Remote conclusion | `{env('REMOTE_RUN_CONCLUSION')}` |",
            f"| Remote run | {env('REMOTE_RUN_URL') or 'not available'} |",
            f"| Scheduler run | {env('SOURCE_RUN_URL')} |",
            "",
            f"Closes #{issue_number}",
        ])

        with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False) as f:
            f.write(body)
            body_path = f.name
        try:
            create = subprocess.run(
                ["gh", "pr", "create", "--repo", repo, "--base", target_ref,
                 "--head", branch, "--title", pr_title, "--body-file", body_path,
                 "--reviewer", maintainer, "--assignee", maintainer],
                env=gh_env(), capture_output=True, text=True, check=True,
            )
            pr_url = create.stdout.strip()
        finally:
            os.unlink(body_path)
    else:
        pr_number = pr_url.rsplit("/", 1)[-1]
        # Re-request the maintainer as reviewer / assignee. Both endpoints are
        # idempotent and harmless if the user is already in the list, so we
        # ignore failures.
        subprocess.run(
            ["gh", "api", "--method", "POST",
             "-H", "Accept: application/vnd.github+json",
             f"/repos/{repo}/pulls/{pr_number}/requested_reviewers",
             "-f", f"reviewers[]={maintainer}"],
            env=gh_env(), capture_output=True, check=False,
        )
        subprocess.run(
            ["gh", "api", "--method", "POST",
             "-H", "Accept: application/vnd.github+json",
             f"/repos/{repo}/issues/{pr_number}/assignees",
             "-f", f"assignees[]={maintainer}"],
            env=gh_env(), capture_output=True, check=False,
        )

    write_output("pr_url", pr_url)
    write_output("pr_number", pr_url.rsplit("/", 1)[-1])
    write_output("branch", branch)
    print(f"Opened remediation PR: {pr_url}")
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

#!/usr/bin/env python3
"""Locate the workflow run we just dispatched in the target repo, then poll
until it completes (or we hit watch_timeout). Emits run_id, run_url,
run_conclusion, and should_open_issue to $GITHUB_OUTPUT.

Required env (provided by the composite action's `env:` block):
    GH_TOKEN, TARGET_OWNER, TARGET_REPO, TARGET_WORKFLOW, TARGET_REF,
    DISPATCHED_AT, APP_SLUG,
    LOOKUP_ATTEMPTS, LOOKUP_INTERVAL, WATCH_ATTEMPTS, WATCH_INTERVAL,
    GITHUB_OUTPUT.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
import time
from typing import Any


# Conclusions that indicate the run failed in a way the scheduler should
# raise a remediation issue for. Matches the case-statement in the bash version.
ISSUE_OPENING_CONCLUSIONS = {
    "failure", "timed_out", "action_required", "startup_failure", "stale",
}


def env(name: str, default: str = "") -> str:
    return os.environ.get(name, default)


def gh_api(path: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [
            "gh", "api",
            "-H", "Accept: application/vnd.github+json",
            "-H", "X-GitHub-Api-Version: 2022-11-28",
            path,
        ],
        capture_output=True, text=True, check=True,
    )


def write_output(key: str, value: str) -> None:
    with open(os.environ["GITHUB_OUTPUT"], "a") as f:
        f.write(f"{key}={value}\n")


def pick_run_id(workflow_runs: list[dict[str, Any]], dispatched_at: str,
                bot_login: str) -> str:
    candidates = [r for r in workflow_runs if (r.get("created_at") or "") >= dispatched_at]
    candidates.sort(key=lambda r: r.get("created_at") or "")
    if not candidates:
        return ""
    if bot_login:
        for run in candidates:
            actor = (
                (run.get("triggering_actor") or {}).get("login")
                or (run.get("actor") or {}).get("login")
                or ""
            )
            if actor == bot_login:
                return str(run.get("id") or "")
    return str(candidates[0].get("id") or "")


def main() -> int:
    owner = env("TARGET_OWNER")
    repo = env("TARGET_REPO")
    workflow = env("TARGET_WORKFLOW")
    ref = env("TARGET_REF")
    dispatched_at = env("DISPATCHED_AT")
    app_slug = env("APP_SLUG")
    bot_login = f"{app_slug}[bot]" if app_slug else ""

    lookup_attempts = int(env("LOOKUP_ATTEMPTS"))
    lookup_interval = float(env("LOOKUP_INTERVAL"))
    watch_attempts = int(env("WATCH_ATTEMPTS"))
    watch_interval = float(env("WATCH_INTERVAL"))

    runs_url = (
        f"/repos/{owner}/{repo}/actions/workflows/{workflow}/runs"
        f"?event=workflow_dispatch&branch={ref}&per_page=20"
    )

    run_id = ""
    for _ in range(lookup_attempts):
        response = json.loads(gh_api(runs_url).stdout)
        run_id = pick_run_id(response.get("workflow_runs") or [], dispatched_at, bot_login)
        if run_id:
            break
        time.sleep(lookup_interval)

    if not run_id:
        write_output("run_conclusion", "dispatch_not_found")
        write_output("should_open_issue", "true")
        return 0

    write_output("run_id", run_id)

    for _ in range(watch_attempts):
        run = json.loads(gh_api(f"/repos/{owner}/{repo}/actions/runs/{run_id}").stdout)
        status = run.get("status") or ""
        conclusion = run.get("conclusion") or ""
        run_url = run.get("html_url") or ""
        suffix = f" ({conclusion})" if conclusion else ""
        print(f"Remote status: {status}{suffix}")

        if status == "completed":
            write_output("run_url", run_url)
            write_output("run_conclusion", conclusion)
            should_open = "true" if conclusion in ISSUE_OPENING_CONCLUSIONS else "false"
            write_output("should_open_issue", should_open)
            return 0

        time.sleep(watch_interval)

    # Watch timed out without seeing a completion.
    write_output("run_url", f"https://github.com/{owner}/{repo}/actions/runs/{run_id}")
    write_output("run_conclusion", "watch_timeout")
    write_output("should_open_issue", "true")
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

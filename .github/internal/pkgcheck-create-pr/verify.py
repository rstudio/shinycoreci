#!/usr/bin/env python3
"""Dispatch the target workflow on the PR branch and watch for the resulting
run. Writes `conclusion`, `run_url`, `run_id`, and `attempt` to $GITHUB_OUTPUT.
Also writes the run log to .shinycoreci-remediation/remote-run.log so a
follow-up Claude attempt can read it.

Required env vars:
    TARGET_GH_TOKEN  GitHub App token for the target repo.
    TARGET_OWNER     Target repo owner.
    TARGET_REPO      Target repo name.
    TARGET_WORKFLOW  Workflow file (e.g. R-CMD-check.yaml) to dispatch.
    PR_BRANCH        Branch (head of the remediation PR) to dispatch on.
    APP_SLUG         GitHub App slug used to filter the matching run.
    LOOKUP_ATTEMPTS  Polls until the dispatched run appears.
    LOOKUP_INTERVAL  Seconds between lookup polls.
    WATCH_ATTEMPTS   Polls until the dispatched run completes.
    WATCH_INTERVAL   Seconds between watch polls.

Args:
    sys.argv[1]  Attempt number (1 or 2), echoed back as the `attempt` output.
"""
from __future__ import annotations

import datetime as _dt
import json
import os
import subprocess
import sys
import time
from pathlib import Path
from typing import Any


def env(name: str, default: str = "") -> str:
    return os.environ.get(name, default)


def gh_env() -> dict[str, str]:
    return {**os.environ, "GH_TOKEN": env("TARGET_GH_TOKEN")}


def gh_api(args: list[str], *, input_data: str | None = None,
           check: bool = True) -> subprocess.CompletedProcess[str]:
    cmd = [
        "gh", "api",
        "-H", "Accept: application/vnd.github+json",
        "-H", "X-GitHub-Api-Version: 2022-11-28",
        *args,
    ]
    return subprocess.run(
        cmd, input=input_data, capture_output=True, text=True,
        check=check, env=gh_env(),
    )


def write_outputs(**kwargs: str) -> None:
    with open(os.environ["GITHUB_OUTPUT"], "a") as f:
        for key, value in kwargs.items():
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


def stash_run_log(repo: str, run_id: str, run_url: str) -> None:
    out_dir = Path(".shinycoreci-remediation")
    out_dir.mkdir(parents=True, exist_ok=True)
    exclude = Path(".git/info/exclude")
    if exclude.parent.is_dir():
        try:
            with exclude.open("a") as f:
                f.write(".shinycoreci-remediation/\n")
        except OSError:
            pass

    log_file = out_dir / "remote-run.log"
    result = subprocess.run(
        ["gh", "run", "view", run_id, "--repo", repo, "--log"],
        capture_output=True, text=True, check=False, env=gh_env(),
    )
    if result.returncode == 0:
        log_file.write_text(result.stdout)
    else:
        log_file.write_text(
            f"Could not download logs for verification run {run_id}.\n"
            f"Verification run URL: {run_url}\n"
        )


def main() -> int:
    attempt = sys.argv[1] if len(sys.argv) > 1 else "1"

    owner = env("TARGET_OWNER")
    repo_name = env("TARGET_REPO")
    repo = f"{owner}/{repo_name}"
    workflow = env("TARGET_WORKFLOW")
    pr_branch = env("PR_BRANCH")
    app_slug = env("APP_SLUG")
    bot_login = f"{app_slug}[bot]" if app_slug else ""

    lookup_attempts = int(env("LOOKUP_ATTEMPTS"))
    lookup_interval = float(env("LOOKUP_INTERVAL"))
    watch_attempts = int(env("WATCH_ATTEMPTS"))
    watch_interval = float(env("WATCH_INTERVAL"))

    dispatched_at = _dt.datetime.now(tz=_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    print(f"Dispatching {repo} {workflow} on PR branch {pr_branch}"
          f" (verification attempt {attempt}).")

    gh_api(
        ["--method", "POST",
         f"/repos/{repo}/actions/workflows/{workflow}/dispatches",
         "--input", "-"],
        input_data=json.dumps({"ref": pr_branch}),
    )

    runs_url = (
        f"/repos/{repo}/actions/workflows/{workflow}/runs"
        f"?event=workflow_dispatch&branch={pr_branch}&per_page=20"
    )

    run_id = ""
    for _ in range(lookup_attempts):
        response = json.loads(gh_api([runs_url]).stdout)
        run_id = pick_run_id(response.get("workflow_runs") or [], dispatched_at, bot_login)
        if run_id:
            break
        time.sleep(lookup_interval)

    if not run_id:
        write_outputs(conclusion="dispatch_not_found", run_url="", run_id="",
                      attempt=attempt)
        return 0

    conclusion = ""
    run_url = ""
    for _ in range(watch_attempts):
        run = json.loads(gh_api([f"/repos/{repo}/actions/runs/{run_id}"]).stdout)
        status = run.get("status") or ""
        conclusion = run.get("conclusion") or ""
        run_url = run.get("html_url") or ""
        suffix = f" ({conclusion})" if conclusion else ""
        print(f"Verification status: {status}{suffix}")
        if status == "completed":
            break
        time.sleep(watch_interval)

    if not conclusion:
        conclusion = "watch_timeout"
        run_url = run_url or f"https://github.com/{repo}/actions/runs/{run_id}"

    stash_run_log(repo, run_id, run_url)

    write_outputs(conclusion=conclusion, run_url=run_url, run_id=run_id,
                  attempt=attempt)
    return 0


if __name__ == "__main__":
    sys.exit(main())

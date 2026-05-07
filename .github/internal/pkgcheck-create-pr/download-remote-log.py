#!/usr/bin/env python3
"""Download the failed remote workflow run's log into .shinycoreci-remediation/.

Required env (provided by the composite action's `env:` block):
    TARGET_GH_TOKEN, TARGET_OWNER, TARGET_REPO,
    REMOTE_RUN_ID, REMOTE_RUN_URL.
"""
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path


def env(name: str, default: str = "") -> str:
    return os.environ.get(name, default)


def main() -> int:
    out_dir = Path(".shinycoreci-remediation")
    out_dir.mkdir(parents=True, exist_ok=True)

    exclude = Path(".git/info/exclude")
    if exclude.parent.is_dir():
        with exclude.open("a") as f:
            f.write(".shinycoreci-remediation/\n")

    log_file = out_dir / "remote-run.log"
    run_id = env("REMOTE_RUN_ID")
    run_url = env("REMOTE_RUN_URL") or "not available"
    repo = f"{env('TARGET_OWNER')}/{env('TARGET_REPO')}"

    if not run_id:
        log_file.write_text(
            f"No remote run ID was available.\nRemote run URL: {run_url}\n"
        )
        return 0

    result = subprocess.run(
        ["gh", "run", "view", run_id, "--repo", repo, "--log"],
        capture_output=True, text=True, check=False,
        env={**os.environ, "GH_TOKEN": env("TARGET_GH_TOKEN")},
    )
    if result.returncode == 0:
        log_file.write_text(result.stdout)
    else:
        log_file.write_text(
            f"Could not download logs for remote run {run_id}.\n"
            f"Remote run URL: {run_url}\n"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())

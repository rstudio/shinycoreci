#!/usr/bin/env python3
import argparse
import json
import re
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path


RESULT_RE = re.compile(
    r"^gha-(?P<sha>[^-]+)-(?P<stamp>\d{4}_\d{2}_\d{2}_\d{2}_\d{2})-(?P<r_version>[^-]+)-(?P<platform>.+)\.json$"
)
SNAPSHOT_PATTERNS = (
    ("snapshot_changed", re.compile(r"Snapshot of .* has changed|snapshot.*changed", re.IGNORECASE)),
    ("snapshot_review", re.compile(r"snapshot_review", re.IGNORECASE)),
    ("snapshot_path", re.compile(r"_snaps|\.new", re.IGNORECASE)),
    ("screenshot_diff", re.compile(r"screenshot.*differ", re.IGNORECASE)),
)


def parse_result_name(path):
    match = RESULT_RE.match(Path(path).name)
    if not match:
        return None
    stamp = datetime.strptime(match.group("stamp"), "%Y_%m_%d_%H_%M").replace(tzinfo=timezone.utc)
    return {
        "sha": match.group("sha"),
        "time": stamp,
        "date": stamp.date().isoformat(),
        "r_version": match.group("r_version"),
        "platform": match.group("platform"),
    }


def read_result(path):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8", errors="replace").replace("\x00", ""))
    except Exception as err:
        print(f"Skipping unreadable result {path}: {err}", file=sys.stderr)
        return None


def clean_excerpt(text, limit=1800):
    text = re.sub(r"\s+", " ", str(text or "")).strip()
    if len(text) <= limit:
        return text
    return text[: limit - 3] + "..."


def snapshot_gate(text):
    for name, pattern in SNAPSHOT_PATTERNS:
        if pattern.search(str(text)):
            return name
    return None


def build_context(results_dir):
    entries = []
    for path in sorted(Path(results_dir).glob("*.json")):
        info = parse_result_name(path)
        if info is None:
            continue
        data = read_result(path)
        if not data or data.get("branch_name") != "main":
            continue
        entries.append({"path": str(path), "info": info, "data": data})

    if not entries:
        raise SystemExit(f"No main-branch test results found in {results_dir}")

    latest_date = max(entry["info"]["date"] for entry in entries)
    latest = [entry for entry in entries if entry["info"]["date"] == latest_date]
    latest.sort(key=lambda entry: (entry["info"]["platform"], entry["info"]["r_version"]))

    failures = []
    for entry in latest:
        for result in entry["data"].get("results", []):
            status = result.get("status")
            if status not in {"fail", "can_not_install"}:
                continue
            text = result.get("result", "")
            gate = snapshot_gate(text)
            failures.append(
                {
                    "app_name": result.get("app_name", ""),
                    "status": status,
                    "platform": entry["info"]["platform"],
                    "r_version": entry["info"]["r_version"],
                    "gha_branch_name": entry["data"].get("gha_branch_name", ""),
                    "snapshot_related": gate is not None,
                    "snapshot_gate": gate,
                    "excerpt": clean_excerpt(text),
                }
            )

    snapshot_failures = [failure for failure in failures if failure["snapshot_related"]]
    sha_counts = Counter(entry["info"]["sha"] for entry in latest)
    base_sha = sha_counts.most_common(1)[0][0]
    year, month, day = latest_date.split("-")

    return {
        "date": latest_date,
        "dashboard_path": f"{year}/{month}/{day}",
        "base_sha": base_sha,
        "run_count": len(latest),
        "failure_count": len(failures),
        "snapshot_failure_count": len(snapshot_failures),
        "failures": failures,
        "snapshot_failures": snapshot_failures,
        "result_files": [entry["path"] for entry in latest],
    }


def build_prompt(context):
    if context["snapshot_failure_count"] == 0:
        action = (
            "No snapshot-related failures were found in the latest nightly run. "
            "do not run fix_snaps. Summarize that there is no snapshot work."
        )
    else:
        action = f"""
Run this repository's existing snapshot repair path for the latest nightly SHA:

```bash
Rscript -e 'shinycoreci::fix_snaps(sha = "{context["base_sha"]}", ask_apps = FALSE, ask_branches = FALSE, ask_if_not_main = FALSE)'
```

Then inspect `git diff -- inst/apps`. Keep only minute/mechanical snapshot updates: tiny pixel drift, generated snapshot metadata churn, platform-only rendering noise, or text/output changes that are clearly equivalent. Revert any app that needs human review with `git checkout -- inst/apps/<app-name>` so only minute accepted snapshots remain in the working tree.
""".strip()

    failure_lines = []
    for failure in context["failures"][:80]:
        marker = failure["snapshot_gate"] or "other"
        failure_lines.append(
            f"- [{marker}] {failure['app_name']} on {failure['platform']} {failure['r_version']} "
            f"({failure['status']}, {failure['gha_branch_name']}): {failure['excerpt']}"
        )

    failures_text = "\n".join(failure_lines) if failure_lines else "- No failures in the latest run."

    return f"""
You are preparing a shinycoreci snapshot review summary.

Latest nightly run:
- Date: {context["date"]}
- Base SHA: {context["base_sha"]}
- Matrix result files: {context.get("run_count", "unknown")}
- Failures: {context["failure_count"]}
- Snapshot-related failures: {context["snapshot_failure_count"]}

Task:
{action}

Rules:
- Do not commit, push, create PRs, or edit files under `_gh-pages/`.
- Do not change workflow files.
- Leave accepted minute snapshot changes in the working tree; this workflow will commit them to a PR.
- If dependencies are missing, install the minimum needed to run the existing R helper.
- Before finishing, write the final Markdown report to `snapshot-analysis/claude-report.md`.

Final report format:
## Summary
One or two sentences for the meeting.

## Minute Changes Accepted
Bullet list of apps/snapshots accepted, or `None`.

## Needs Human Review
Bullet list of apps/snapshots not accepted and why, or `None`.

## Commands Run
Bullet list of important commands and whether they passed.

Latest failures:
{failures_text}
""".strip()


def write_outputs(context, out_dir):
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    context_path = out_dir / "context.json"
    prompt_path = out_dir / "prompt.md"
    context_path.write_text(json.dumps(context, indent=2) + "\n")
    prompt_path.write_text(build_prompt(context) + "\n")
    return context_path, prompt_path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--results-dir", required=True)
    parser.add_argument("--out-dir", required=True)
    args = parser.parse_args()

    context = build_context(args.results_dir)
    context_path, prompt_path = write_outputs(context, args.out_dir)

    print(f"date={context['date']}")
    print(f"dashboard_path={context['dashboard_path']}")
    print(f"base_sha={context['base_sha']}")
    print(f"has_snapshot_failures={str(context['snapshot_failure_count'] > 0).lower()}")
    print(f"context_file={context_path}")
    print(f"prompt_file={prompt_path}")


if __name__ == "__main__":
    main()

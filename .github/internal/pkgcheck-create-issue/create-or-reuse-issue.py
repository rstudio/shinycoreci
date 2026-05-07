#!/usr/bin/env python3
"""Create or reuse a remediation issue for a failing remote workflow run.

Ensures any requested labels exist in the target repository before opening.

Required env (provided by the composite action's `env:` block):
    APP_GH_TOKEN, SOURCE_REPOSITORY, SOURCE_RUN_URL,
    TARGET_OWNER, TARGET_REPO, TARGET_REF, TARGET_WORKFLOW, TARGET_MAINTAINER,
    REMOTE_RUN_CONCLUSION, REMOTE_RUN_URL,
    INPUT_ISSUE_TITLE, INPUT_CUSTOM_INSTRUCTIONS, INPUT_ISSUE_LABELS,
    GITHUB_OUTPUT.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
from typing import Any
from urllib.parse import quote


def env(name: str, default: str = "") -> str:
    return os.environ.get(name, default)


def gh_env() -> dict[str, str]:
    return {**os.environ, "GH_TOKEN": env("APP_GH_TOKEN")}


def gh_api(
    args: list[str],
    *,
    input_data: str | None = None,
) -> subprocess.CompletedProcess[str]:
    cmd = [
        "gh", "api",
        "-H", "Accept: application/vnd.github+json",
        "-H", "X-GitHub-Api-Version: 2022-11-28",
        *args,
    ]
    return subprocess.run(
        cmd,
        input=input_data,
        capture_output=True,
        text=True,
        check=False,
        env=gh_env(),
    )


def write_outputs(issue: dict[str, Any], mode: str, existing_pr_url: str = "") -> None:
    with open(os.environ["GITHUB_OUTPUT"], "a") as f:
        f.write(f"issue_url={issue['html_url']}\n")
        f.write(f"issue_number={issue['number']}\n")
        f.write(f"issue_mode={mode}\n")
        f.write(f"existing_pr_url={existing_pr_url}\n")


def parse_labels(raw: str) -> list[str]:
    return sorted({s.strip() for s in raw.split(",") if s.strip()})


def ensure_label_exists(label: str) -> None:
    owner, repo = env("TARGET_OWNER"), env("TARGET_REPO")
    probe = gh_api([f"/repos/{owner}/{repo}/labels/{quote(label, safe='')}"])
    if probe.returncode == 0:
        return

    payload = json.dumps({
        "name": label,
        "color": "ededed",
        "description": "Automatically opened by shinycoreci scheduler with AI assistance.",
    })
    gh_api(
        ["--method", "POST", f"/repos/{owner}/{repo}/labels", "--input", "-"],
        input_data=payload,
    )


def _decode_concatenated_json(text: str) -> list[Any]:
    """Decode the stream produced by `gh api --paginate` for array endpoints,
    which emits each page as its own JSON array back-to-back."""
    decoder = json.JSONDecoder()
    out: list[Any] = []
    idx, n = 0, len(text)
    while idx < n:
        while idx < n and text[idx].isspace():
            idx += 1
        if idx >= n:
            break
        value, idx = decoder.raw_decode(text, idx)
        if isinstance(value, list):
            out.extend(value)
        else:
            out.append(value)
    return out


def find_existing_issue(title: str, marker: str) -> dict[str, Any] | None:
    owner, repo = env("TARGET_OWNER"), env("TARGET_REPO")
    result = gh_api([
        "--paginate",
        f"/repos/{owner}/{repo}/issues?state=open&per_page=100",
    ])
    if result.returncode != 0 or not result.stdout.strip():
        return None

    candidates = _decode_concatenated_json(result.stdout)
    matching = [
        i for i in candidates
        if isinstance(i, dict)
        and not i.get("pull_request")
        and (i.get("title") == title or marker in (i.get("body") or ""))
    ]
    if not matching:
        return None
    matching.sort(key=lambda i: i.get("created_at") or "")
    return matching[0]


def find_open_linked_pr(issue_number: int) -> str:
    query = (
        "query($owner:String!,$repo:String!,$number:Int!){"
        "repository(owner:$owner,name:$repo){"
        "issue(number:$number){"
        "timelineItems(first:100,itemTypes:[CROSS_REFERENCED_EVENT]){"
        "nodes{__typename ... on CrossReferencedEvent{"
        "source{__typename ... on PullRequest{url state isDraft}}}}}}}}"
    )
    result = subprocess.run(
        [
            "gh", "api", "graphql",
            "-f", f"query={query}",
            "-F", f"owner={env('TARGET_OWNER')}",
            "-F", f"repo={env('TARGET_REPO')}",
            "-F", f"number={issue_number}",
        ],
        capture_output=True, text=True, check=False, env=gh_env(),
    )
    if result.returncode != 0:
        return ""
    try:
        data = json.loads(result.stdout)
    except json.JSONDecodeError:
        return ""

    nodes = (
        (((data.get("data") or {}).get("repository") or {})
         .get("issue") or {}).get("timelineItems") or {}
    ).get("nodes") or []
    for node in nodes:
        src = node.get("source") or {}
        if src.get("__typename") == "PullRequest" and src.get("state") == "OPEN":
            return src.get("url") or ""
    return ""


def reuse_issue(issue: dict[str, Any]) -> None:
    pr_url = find_open_linked_pr(int(issue["number"]))
    write_outputs(issue, "existing", pr_url)
    print(f"Open remediation issue already exists: {issue['html_url']}")
    if pr_url:
        print(f"Open remediation PR already linked: {pr_url}")
    sys.exit(0)


def build_issue_body(marker: str, custom_instructions: str) -> str:
    src_repo = env("SOURCE_REPOSITORY")
    target = f"{env('TARGET_OWNER')}/{env('TARGET_REPO')}"
    remote_run_url = env("REMOTE_RUN_URL") or "not available"

    lines = [
        f"<!-- {marker} -->",
        "",
        "> [!NOTE]",
        f"> This issue was opened automatically by the `{src_repo}` scheduler."
        " An AI-assisted solver may attempt a fix; review carefully before merging.",
        "",
        "## Summary",
        "",
        f"The scheduled package checks triggered from `{src_repo}` failed for"
        f" `{target}` on `{env('TARGET_REF')}`.",
        "",
        "## Failure details",
        "",
        "| Field | Value |",
        "| --- | --- |",
        f"| Target repository | `{target}` |",
        f"| Target ref | `{env('TARGET_REF')}` |",
        f"| Remote workflow | `{env('TARGET_WORKFLOW')}` |",
        f"| Remote conclusion | `{env('REMOTE_RUN_CONCLUSION')}` |",
        f"| Remote run | {remote_run_url} |",
        f"| Source scheduler | `{src_repo}` |",
        f"| Scheduler run | {env('SOURCE_RUN_URL')} |",
        f"| Suggested maintainer | @{env('TARGET_MAINTAINER')} |",
    ]
    if custom_instructions:
        lines += ["", "## Additional instructions", "", custom_instructions]
    return "\n".join(lines)


def main() -> int:
    title = env("INPUT_ISSUE_TITLE") or (
        f"Automated fix: {env('TARGET_REPO')} package checks failing on"
        f" {env('TARGET_REF')}"
    )

    labels = parse_labels(env("INPUT_ISSUE_LABELS"))
    for label in labels:
        ensure_label_exists(label)

    marker = (
        f"shinycoreci-remediation: {env('TARGET_OWNER')}/{env('TARGET_REPO')}"
        f":{env('TARGET_WORKFLOW')}:{env('TARGET_REF')}"
    )

    existing = find_existing_issue(title, marker)
    if existing:
        reuse_issue(existing)

    body = build_issue_body(marker, env("INPUT_CUSTOM_INSTRUCTIONS"))
    payload = json.dumps({
        "title": title,
        "body": body,
        "assignees": [env("TARGET_MAINTAINER")],
        "labels": labels,
    })

    owner, repo = env("TARGET_OWNER"), env("TARGET_REPO")
    result = gh_api(
        ["--method", "POST", f"/repos/{owner}/{repo}/issues", "--input", "-"],
        input_data=payload,
    )

    if result.returncode != 0:
        # Race: another run may have opened the issue between our search and
        # our POST. Re-check and reuse if so.
        existing = find_existing_issue(title, marker)
        if existing:
            reuse_issue(existing)
        print("::error::Failed to create remediation issue.")
        if result.stdout:
            sys.stdout.write(result.stdout)
            if not result.stdout.endswith("\n"):
                sys.stdout.write("\n")
        if result.stderr:
            sys.stderr.write(result.stderr)
            if not result.stderr.endswith("\n"):
                sys.stderr.write("\n")
        return result.returncode

    issue = json.loads(result.stdout)
    write_outputs(issue, "created")
    print(f"Created remediation issue (created): {issue['html_url']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

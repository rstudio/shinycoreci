#!/usr/bin/env python3
import argparse
import html
import json
import re
import time
from datetime import datetime, timezone
from pathlib import Path


CARD_BEGIN = "<!-- shinycoreci-snapshot-analysis:begin -->"
CARD_END = "<!-- shinycoreci-snapshot-analysis:end -->"


def load_events(path):
    if not path:
        return []
    path = Path(path)
    if not path.exists():
        return []
    text = path.read_text(encoding="utf-8", errors="replace").strip()
    if not text:
        return []
    try:
        data = json.loads(text)
        if isinstance(data, list):
            return data
        return [data]
    except json.JSONDecodeError:
        events = []
        for line in text.splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                events.append(json.loads(line))
            except json.JSONDecodeError:
                pass
        return events


def find_number(obj, keys):
    if isinstance(obj, dict):
        for key in keys:
            value = obj.get(key)
            if isinstance(value, (int, float)):
                return value
        for value in obj.values():
            found = find_number(value, keys)
            if found is not None:
                return found
    elif isinstance(obj, list):
        for value in obj:
            found = find_number(value, keys)
            if found is not None:
                return found
    return None


def assistant_text(entry):
    blocks = entry.get("message", {}).get("content", [])
    if not isinstance(blocks, list):
        return ""
    return "\n".join(block.get("text", "") for block in blocks if block.get("type") == "text").strip()


def read_claude_execution(path):
    events = load_events(path)
    result_event = next((event for event in reversed(events) if event.get("type") == "result"), {})
    report = str(result_event.get("result") or "").strip()
    if not report:
        report = next((assistant_text(event) for event in reversed(events) if assistant_text(event)), "")

    duration_ms = find_number(result_event, ("duration_ms", "duration_api_ms"))
    duration_seconds = None
    if duration_ms is not None:
        duration_seconds = round(duration_ms / 1000)
    else:
        duration_seconds = find_number(result_event, ("duration_seconds", "elapsed_seconds"))

    return {
        "report": report,
        "cost_usd": find_number(result_event, ("total_cost_usd", "cost_usd")),
        "duration_seconds": duration_seconds,
        "num_turns": find_number(result_event, ("num_turns",)),
    }


def fmt_cost(value):
    if value is None:
        return "n/a"
    return f"${value:.4f}"


def fmt_duration(seconds):
    if seconds is None:
        return "n/a"
    seconds = int(seconds)
    minutes, seconds = divmod(seconds, 60)
    if minutes:
        return f"{minutes}m {seconds}s"
    return f"{seconds}s"


def inject_dashboard_card(page_html, card_html):
    pattern = re.compile(re.escape(CARD_BEGIN) + r".*?" + re.escape(CARD_END), re.DOTALL)
    page_html = pattern.sub("", page_html)
    block = f"\n{CARD_BEGIN}\n{card_html}\n{CARD_END}\n"
    match = re.search(r"<body[^>]*>", page_html, re.IGNORECASE)
    if match:
        return page_html[: match.end()] + block + page_html[match.end() :]
    return block + page_html


def render_card(metadata):
    link = html.escape(metadata["analysis_href"])
    pr_url = metadata.get("pr_url") or ""
    pr_html = (
        f'<a href="{html.escape(pr_url)}">Accepted snapshot PR</a>'
        if pr_url
        else "No accepted snapshot PR"
    )
    return f"""
<section class="snapshot-ai-analysis" style="border:1px solid #dee2e6;border-radius:8px;padding:1rem 1.25rem;margin:1rem 0 1.5rem;background:#fafbfc;">
  <h2 style="font-size:1.1rem;margin:0 0 .5rem;">Claude Snapshot Analysis</h2>
  <p style="margin:.25rem 0;color:#495057;">{html.escape(metadata["summary"])}</p>
  <p style="margin:.5rem 0 0;color:#6c757d;font-size:.9rem;">
    Model: <code>{html.escape(metadata["model"])}</code> ·
    Cost: <strong>{html.escape(fmt_cost(metadata.get("cost_usd")))}</strong> ·
    Time: <strong>{html.escape(fmt_duration(metadata.get("duration_seconds")))}</strong> ·
    {pr_html} ·
    <a href="{link}">Full analysis</a>
  </p>
</section>
""".strip()


def render_page(metadata, report):
    title = f"Claude Snapshot Analysis - {metadata['date']}"
    changed_files = metadata.get("changed_files") or []
    changed_html = "\n".join(f"<li><code>{html.escape(path)}</code></li>" for path in changed_files)
    if not changed_html:
        changed_html = "<li>None</li>"
    return f"""<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>{html.escape(title)}</title>
  <style>
    body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; margin: 2rem auto; max-width: 1100px; line-height: 1.45; padding: 0 1rem; }}
    code, pre {{ font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; }}
    pre {{ white-space: pre-wrap; border: 1px solid #dee2e6; border-radius: 8px; padding: 1rem; background: #f8f9fa; }}
    .meta {{ color: #495057; }}
  </style>
</head>
<body>
  <p><a href="../">Back to results dashboard</a></p>
  <h1>{html.escape(title)}</h1>
  <p class="meta">
    Model: <code>{html.escape(metadata["model"])}</code> ·
    Cost: <strong>{html.escape(fmt_cost(metadata.get("cost_usd")))}</strong> ·
    Time: <strong>{html.escape(fmt_duration(metadata.get("duration_seconds")))}</strong> ·
    Published: {html.escape(metadata["published_at"])}
  </p>
  <h2>Report</h2>
  <pre>{html.escape(report or "No Claude report was produced.")}</pre>
  <h2>Accepted Snapshot Files</h2>
  <ul>{changed_html}</ul>
</body>
</html>
"""


def first_summary_line(report):
    for line in (report or "").splitlines():
        line = line.strip().lstrip("#").strip()
        if line and line.lower() not in {"summary"}:
            return line
    return "No Claude report was produced."


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--context", required=True)
    parser.add_argument("--gh-pages", required=True)
    parser.add_argument("--model", required=True)
    parser.add_argument("--execution-file", default="")
    parser.add_argument("--report-file", default="")
    parser.add_argument("--changed-files", default="")
    parser.add_argument("--pr-url", default="")
    parser.add_argument("--workflow-start", type=float, default=0)
    parser.add_argument("--skipped", action="store_true")
    args = parser.parse_args()

    context = json.loads(Path(args.context).read_text())
    execution = read_claude_execution(args.execution_file)
    report_path = Path(args.report_file) if args.report_file else None
    if report_path and report_path.exists():
        execution["report"] = report_path.read_text(encoding="utf-8", errors="replace").strip()
    if args.skipped:
        execution["cost_usd"] = 0
        execution["duration_seconds"] = 0
        execution["report"] = execution["report"] or "No snapshot-related failures found; Claude Code was skipped."
    elif execution["duration_seconds"] is None and args.workflow_start:
        execution["duration_seconds"] = round(time.time() - args.workflow_start)

    changed_files = []
    changed_path = Path(args.changed_files) if args.changed_files else None
    if changed_path and changed_path.exists():
        changed_files = [line.strip() for line in changed_path.read_text().splitlines() if line.strip()]

    gh_pages = Path(args.gh_pages)
    result_dir = gh_pages / "results" / context["dashboard_path"]
    analysis_dir = result_dir / "snapshot-analysis"
    analysis_dir.mkdir(parents=True, exist_ok=True)

    metadata = {
        "date": context["date"],
        "base_sha": context["base_sha"],
        "model": args.model,
        "cost_usd": execution["cost_usd"],
        "duration_seconds": execution["duration_seconds"],
        "num_turns": execution["num_turns"],
        "summary": first_summary_line(execution["report"]),
        "analysis_href": "snapshot-analysis/",
        "pr_url": args.pr_url,
        "changed_files": changed_files,
        "published_at": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC"),
    }

    (analysis_dir / "data.json").write_text(json.dumps({**metadata, "report": execution["report"]}, indent=2) + "\n")
    (analysis_dir / "index.html").write_text(render_page(metadata, execution["report"]))

    latest_dir = gh_pages / "results" / "snapshot-analysis"
    latest_dir.mkdir(parents=True, exist_ok=True)
    latest_href = "../" + context["dashboard_path"] + "/snapshot-analysis/"
    (latest_dir / "index.html").write_text(
        f'<!DOCTYPE html><html><head><meta http-equiv="refresh" content="0; url={html.escape(latest_href)}"></head>'
        f'<body><p><a href="{html.escape(latest_href)}">Latest snapshot analysis</a></p></body></html>\n'
    )

    dashboard = result_dir / "index.html"
    if dashboard.exists():
        dashboard.write_text(inject_dashboard_card(dashboard.read_text(errors="replace"), render_card(metadata)))


if __name__ == "__main__":
    main()

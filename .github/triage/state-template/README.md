# Triage State Template

The running workflow stores durable state in repo memory on the `triage-state` branch, mounted at `/tmp/gh-aw/repo-memory-triage/`.

Expected state files:

- `cursors.json`: last scanned timestamps per repository.
- `issues/<owner-repo>.jsonl`: normalized issue snapshots for bounded duplicate checks.
- `triage-results/<YYYY-MM-DD>.jsonl`: machine-readable decisions and audit trail.
- `duplicates/candidates.jsonl`: duplicate candidates, confidence, and rationale.

This template is checked into the implementation branch only as a starting reference. The workflow owns the live state files.
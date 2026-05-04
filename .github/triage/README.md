# Team Issue Triage

`.github/workflows/team-issue-triage.yml` runs Claude Code through AWS Bedrock once a week (Thursday 08:00 UTC) and on manual dispatch. It is scoped by `.github/triage/team-issue-triage.yaml`; initial rollout is `rstudio/reactlog` only.

## Files

- `team-issue-triage.yaml`: repo allowlist, report repo, scan limits, Bedrock/provider guardrails, and state paths.
- `labels.yaml`: label taxonomy and `allowed_safe_output_labels`, which the post-processing validator reads at runtime.
- `issue-triage-rubric.md`: compact decision rubric passed to Claude.

State is written to the long-lived `triage-state` branch as `cursors.json`, `issues/*.jsonl`, `triage-results/*.jsonl`, and `duplicates/candidates.jsonl`.

## Configuration

Required secrets/vars:

- Org secrets inherited by this repo: `POSIT_SHINY_AUTOMATION_CLIENT_ID`, `POSIT_SHINY_AUTOMATION_PEM`.
- Repo secret or var: `AWS_BEDROCK_ROLE_TO_ASSUME`.
- Optional vars: `AWS_REGION`/`AWS_BEDROCK_REGION`, `ANTHROPIC_MODEL`, `TRIAGE_APPLY_WRITES`, `TRIAGE_PROJECT_URL`.
- Optional secret for project writes: `TRIAGE_PROJECT_TOKEN`.

Do not set `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN`; Bedrock auth comes from AWS OIDC. Writes are off by default (`TRIAGE_APPLY_WRITES=false`, dispatch input `apply_writes=false`).

## Adding Repos

1. Install the `posit-shiny-automation` GitHub App on the repo with issue write access.
2. Add `owner/repo` to `repositories:` in `team-issue-triage.yaml`.
3. Create the labels listed in `labels.yaml` before enabling writes.

All allowlisted repos must share one owner because `actions/create-github-app-token` receives a single owner.

## Validation

```bash
python3 -c 'import yaml; [yaml.safe_load(open(p)) for p in [".github/workflows/team-issue-triage.yml", ".github/triage/team-issue-triage.yaml", ".github/triage/labels.yaml"]]'
rg 'api\.githubcopilot|api\.anthropic\.com|statsig\.anthropic\.com|ANTHROPIC_API_KEY|CLAUDE_CODE_OAUTH_TOKEN' .github/workflows/team-issue-triage.yml
```

The `rg` command should return no matches.

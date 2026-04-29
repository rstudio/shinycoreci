# Team Issue Triage Setup

This directory configures the scheduled `gh-aw` workflow in `.github/workflows/team-issue-triage.md`. The committed runtime lock runs Claude Code through AWS Bedrock Anthropic only: AWS OIDC supplies credentials, `CLAUDE_CODE_USE_BEDROCK=1` selects Bedrock mode, and the lock has no direct `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN` path.

## What Is Included

- A cross-repository triage workflow that scans `rstudio/shiny`, `rstudio/bslib`, `rstudio/htmltools`, `rstudio/httpuv`, and `rstudio/shinycoreci`.
- A small label taxonomy and priority rubric.
- Repo-memory state stored on the `triage-state` branch.
- Safe outputs for labels, approved comments, central report issues, and project item additions.
- Report-only behavior by default through the deterministic dry-run guard.
- AI threat detection disabled so safe-output handling does not add a second model call path outside Bedrock.

## Required GitHub Variables

Set these repository or organization variables:

```bash
gh variable set AWS_REGION --body "us-east-1"
gh variable set ANTHROPIC_MODEL --body "<bedrock-inference-profile-or-model-id>"
gh variable set AWS_BEDROCK_ROLE_TO_ASSUME --body "arn:aws:iam::<account-id>:role/gh-aw-triage"
gh variable set TRIAGE_PROJECT_URL --body "https://github.com/orgs/rstudio/projects/<project-number>"
gh variable set TRIAGE_APPLY_WRITES --body "false"
```

Use the Amazon Bedrock model ID or inference profile ID that is enabled in `AWS_REGION`, for example an Anthropic Claude Sonnet profile such as `us.anthropic.claude-sonnet-4-5-20250929-v1:0` when available in your account.

Keep `TRIAGE_APPLY_WRITES=false` for the dry run. Change it to `true`, or use the manual workflow input `apply_writes=true`, after the team has reviewed preview output.

## Required GitHub Secrets

Set these secrets after creating the corresponding tokens:

```bash
gh aw secrets set GH_AW_GITHUB_MCP_SERVER_TOKEN --value "<read-token-for-gh-aw-github-tools>"
gh aw secrets set GH_AW_TRIAGE_WRITE_TOKEN --value "<issues-labels-comments-write-token>"
gh aw secrets set GH_AW_WRITE_PROJECT_TOKEN --value "<projects-read-write-token>"
```

`GH_AW_GITHUB_MCP_SERVER_TOKEN` needs read access to contents, issues, pull requests, labels, search, and projects for the allowlisted repositories.

`GH_AW_TRIAGE_WRITE_TOKEN` needs issue label/comment write access for the allowlisted repositories. It is only used by safe-output jobs, not by the agent.

`GH_AW_WRITE_PROJECT_TOKEN` needs organization Projects read/write access. For an org-owned project, use a fine-grained PAT with organization `Projects: Read and write`, plus repository `Contents: Read`, `Issues: Read`, and `Pull requests: Read` for the participating repos.

Do not set `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN`. Bedrock authentication is supplied by AWS OIDC.

## AWS Bedrock OIDC Setup

Create an IAM role trusted by this repository's GitHub Actions OIDC provider. The trust policy should restrict `sub` to this repository and branch/environment as tightly as your rollout permits. The role needs Bedrock model invocation permissions for the selected Anthropic model.

Minimal permission shape:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": "arn:aws:bedrock:*::foundation-model/*anthropic*"
    }
  ]
}
```

Also make sure the selected Anthropic model is enabled in Amazon Bedrock for `AWS_REGION`.

## Project Setup

Create the project board once, then put its URL in `TRIAGE_PROJECT_URL`:

```bash
export GH_AW_PROJECT_GITHUB_TOKEN="<projects-read-write-token>"
gh aw project new "Shiny Team Triage" --owner rstudio --link rstudio/shinycoreci --with-project-setup
```

The workflow expects fields named `Priority`, `Priority rank`, `Repository`, `Issue type`, `Triage status`, `Confidence`, `Well-defined`, and `Evidence link`. The `--with-project-setup` command creates a useful starting board, but you may need to add or rename fields to match `.github/triage/team-issue-triage.yaml`.

## Labels

The safe-output configuration can create missing labels when writes are enabled. For a cleaner rollout, create the labels in each participating repository first:

```bash
for repo in rstudio/shiny rstudio/bslib rstudio/htmltools rstudio/httpuv rstudio/shinycoreci; do
  gh label create "regression" --repo "$repo" --color "d73a4a" --description "Current behavior appears worse than an older released version" || true
  gh label create "duplicate" --repo "$repo" --color "cfd3d7" --description "Substantially covered by another issue" || true
  gh label create "wrong location" --repo "$repo" --color "fbca04" --description "Likely belongs in another repository or upstream" || true
  gh label create "needs reprex" --repo "$repo" --color "fef2c0" --description "Needs runnable minimal reproduction" || true
  gh label create "needs clarification" --repo "$repo" --color "fef2c0" --description "Needs specific missing information" || true
  gh label create "priority: P0" --repo "$repo" --color "b60205" --description "Production-breaking, security-sensitive, data loss, or release blocker" || true
  gh label create "priority: P1" --repo "$repo" --color "d93f0b" --description "High-priority regression or severe bug" || true
  gh label create "priority: P2" --repo "$repo" --color "fbca04" --description "Moderate impact bug or request" || true
  gh label create "priority: P3" --repo "$repo" --color "0e8a16" --description "Low-impact backlog item" || true
  gh label create "ai-triage:needs-review" --repo "$repo" --color "5319e7" --description "AI triage needs human review" || true
  gh label create "ai-triage:done" --repo "$repo" --color "bfd4f2" --description "AI triage completed" || true
done
```

Create `ai-triage:report` in `rstudio/shinycoreci` if you want report issues labeled before the first write-enabled run.

## Local Validation

Compile and validate after changing workflow frontmatter:

```bash
gh aw compile team-issue-triage --validate --no-emit
```

The checked-in lock is intentionally Bedrock-only patched because local `gh-aw v0.43.20` still injects direct Claude API/OAuth secret handling when it regenerates built-in Claude workflows. If you intentionally regenerate `.github/workflows/team-issue-triage.lock.yml`, re-check the lock before pushing:

```bash
rg 'ANTHROPIC_API_KEY|CLAUDE_CODE_OAUTH_TOKEN|api\.anthropic\.com|statsig\.anthropic\.com' .github/workflows/team-issue-triage.lock.yml
```

That command should return no matches.

Run a staged manual trial after the branch is pushed and variables/secrets exist:

```bash
gh aw run team-issue-triage --ref triage-state
```

## Rollout

1. Keep `TRIAGE_APPLY_WRITES=false` and review staged safe-output previews.
2. Enable labels only by reviewing `add_labels` previews and then setting `TRIAGE_APPLY_WRITES=true` for manual runs.
3. Add project writes once `TRIAGE_PROJECT_URL` and project fields are confirmed.
4. Leave direct comments staged until the team approves the templates and false-positive rate.
# Team Issue Triage Setup

This directory configures the scheduled workflow in `.github/workflows/team-issue-triage.yml`. The workflow runs Claude Code through `anthropics/claude-code-action` using AWS Bedrock Anthropic only. AWS OIDC supplies model credentials, `use_bedrock: "true"` selects Bedrock mode, and the workflow intentionally avoids GitHub Copilot services and direct Anthropic API/OAuth secrets.

## What Is Included

- A cross-repository triage workflow that scans `rstudio/shiny`, `rstudio/bslib`, `rstudio/htmltools`, `rstudio/httpuv`, and `rstudio/shinycoreci`.
- A small label taxonomy and priority rubric.
- Durable state stored on the `triage-state` branch.
- Structured Claude output that is validated before any label, comment, report, or project write happens.
- Report-only behavior by default through the deterministic dry-run guard.
- No GitHub Copilot MCP endpoint or direct Anthropic API/OAuth path.

## Required GitHub Variables

Set these repository or organization variables:

```bash
gh variable set AWS_REGION --body "us-east-1"
gh variable set ANTHROPIC_MODEL --body "<bedrock-inference-profile-or-model-id>"
gh variable set AWS_BEDROCK_ROLE_TO_ASSUME --body "arn:aws:iam::<account-id>:role/shiny-triage-bedrock"
gh variable set TRIAGE_PROJECT_URL --body "https://github.com/orgs/rstudio/projects/<project-number>"
gh variable set TRIAGE_APPLY_WRITES --body "false"
```

Use the Amazon Bedrock model ID or inference profile ID that is enabled in `AWS_REGION`, for example an Anthropic Claude Sonnet profile such as `us.anthropic.claude-sonnet-4-5-20250929-v1:0` when available in your account.

Keep `TRIAGE_APPLY_WRITES=false` for the dry run. Change it to `true`, or use the manual workflow input `apply_writes=true`, after the team has reviewed preview output.

## Required GitHub Secrets

Set these secrets after creating a GitHub App installed on all allowlisted repositories. The workflow currently uses the same app secret names as the rest of the Shiny automation:

```bash
gh secret set POSIT_SHINY_AUTOMATION_APP_ID --body "<app-client-id-or-app-id>"
gh secret set POSIT_SHINY_AUTOMATION_PEM --body-file ./triage-github-app.private-key.pem
gh secret set TRIAGE_PROJECT_TOKEN --body "<projects-read-write-token>"
```

The GitHub App needs read access to contents, actions, issues, and pull requests for the allowlisted repositories. It also needs issue write access because a second installation token is created for the deterministic post-processing step. The Claude step receives only the read-only token.

`TRIAGE_PROJECT_TOKEN` needs organization Projects read/write access. For an org-owned project, use a fine-grained PAT with organization `Projects: Read and write`, plus repository `Contents: Read`, `Issues: Read`, and `Pull requests: Read` for the participating repos.

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
gh project create --owner rstudio --title "Shiny Team Triage"
```

The workflow expects fields named `Priority`, `Priority rank`, `Repository`, `Issue type`, `Triage status`, `Confidence`, `Well-defined`, and `Evidence link`. You may need to add or rename fields to match `.github/triage/team-issue-triage.yaml`.

## Labels

The post-processing step can apply missing labels when writes are enabled. For a cleaner rollout, create the labels in each participating repository first:

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

Validate the workflow and check that no Copilot or direct Anthropic endpoint remains:

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/team-issue-triage.yml"); YAML.load_file(".github/triage/team-issue-triage.yaml")'
rg 'api\.githubcopilot|github/gh-aw|GH_AW|gh aw|api\.anthropic\.com|statsig\.anthropic\.com|ANTHROPIC_API_KEY|CLAUDE_CODE_OAUTH_TOKEN' .github/workflows/team-issue-triage.yml
```

The `rg` command should return no matches from `.github/workflows/team-issue-triage.yml`.

Run a staged manual trial after the branch is pushed and variables/secrets exist:

```bash
gh workflow run team-issue-triage.yml --ref triage-state
```

## Rollout

1. Keep `TRIAGE_APPLY_WRITES=false` and review dry-run previews.
2. Enable labels only after reviewing dry-run previews, then set `TRIAGE_APPLY_WRITES=true` for manual runs.
3. Add project writes once `TRIAGE_PROJECT_URL` and project fields are confirmed.
4. Leave direct comments staged until the team approves the templates and false-positive rate.

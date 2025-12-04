# Generate a repository event.

This function uses the GitHub API to create a [repository dispatch
event](https://developer.github.com/v3/repos/#create-a-repository-dispatch-event)
that can trigger workflows.

## Usage

``` r
trigger(
  event_type,
  repo = "rstudio/shinycoreci",
  client_payload = list(),
  auth_token = Sys.getenv("GITHUB_PAT")
)

trigger_tests(
  repo = "rstudio/shinycoreci",
  auth_token = Sys.getenv("GITHUB_PAT")
)

trigger_deploy(
  repo = "rstudio/shinycoreci",
  auth_token = Sys.getenv("GITHUB_PAT")
)

trigger_docker(
  repo = "rstudio/shinycoreci",
  auth_token = Sys.getenv("GITHUB_PAT")
)

trigger_results(
  repo = "rstudio/shinycoreci",
  auth_token = Sys.getenv("GITHUB_PAT")
)
```

## Arguments

- event_type:

  The name of the event to create on the repository

- repo:

  The GitHub repo to create the event on; defaults to
  rstudio/shinycoreci

- client_payload:

  The JSON object to make available in the workflow as the
  `github.event.client_payload` object

- auth_token:

  Your GitHub **P**ersonal **A**ccess **T**oken; defaults to
  `Sys.getenv("GITHUB_PAT")`

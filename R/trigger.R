#' Generate a repository event.
#'
#' @description This function uses the GitHub API to create a [repository
#'   dispatch
#'   event](https://developer.github.com/v3/repos/#create-a-repository-dispatch-event)
#'    that can trigger workflows. Currently, the `testthat.yml` workflow
#'   registers itself for the `shinytest-apps` event, and so can be initiated by
#'   running this function with an `event_type` of "shinytest-apps".
#'
#' @param event_type The name of the event to create on the repository
#' @param repo The GitHub repo to create the event on; defaults to
#'   rstudio/shinycoreci-apps
#' @param client_payload The JSON object to make available in the workflow as
#'   the `github.event.client_payload` object
#' @param auth_token Your GitHub OAuth2 token; defaults to
#'   `Sys.getenv("GITHUB_PAT")`
#'
#' @export
#' @rdname trigger
trigger <- function(
  event_type,
  repo = "rstudio/shinycoreci-apps",
  client_payload = list(),
  auth_token = Sys.getenv("GITHUB_PAT")
) {

  req <- httr::POST(
    sprintf("https://api.github.com/repos/%s/dispatches", repo),
    httr::content_type_json(),
    body = list(
      event_type = event_type,
      client_payload = client_payload
    ),
    encode = "json",
    httr::add_headers(
      Authorization = paste0("token ", auth_token),
      Accept = "application/vnd.github.v3+json, application/vnd.github.everest-preview+json"
    )
  )
  invisible(httr::content(req, as = "parsed"))
}

#' @export
#' @rdname trigger
trigger_deploy <- function(
  repo = "rstudio/shinycoreci-apps",
  auth_token = Sys.getenv("GITHUB_PAT")
) {
  trigger("deploy", repo = repo, auth_token = auth_token)
}

#' @export
#' @rdname trigger
trigger_docker <- function(
  repo = "rstudio/shinycoreci-apps",
  auth_token = Sys.getenv("GITHUB_PAT")
) {
  trigger("docker", repo = repo, auth_token = auth_token)
}

# Remove files, but only try to remove if they exist (so we don't get
# warnings).
rm_files <- function(filenames) {
  # Only try to remove files that actually exist
  filenames <- filenames[file.exists(filenames)]
  file.remove(filenames)
}

# This function is never called; it exists only to make R CMD check happy that
# these packages are used.
`_dummy_` <- function() {
  shiny::runApp
  renv::snapshot
  remotes::available_packages
  htmltools::a
  httpuv::decodeURI
  promises::promise
  later::later
  htmlwidgets::JS
  reactlog::reactlog_render
  fastmap::fastmap
  websocket::WebSocket
  plotly::plot_ly
  leaflet::leaflet
  leaflet.providers::get_providers
  crosstalk::crosstalkLibs
  flexdashboard::flex_dashboard
  shinymeta::formatCode
  pool::Pool
  Rcpp::cppFunction
}

# Is this a SHA-1 hash? (vectorized)
is_sha <- function(x) {
  !is.na(x) &
    nchar(x) == 40 &
    sub("[0-9a-f]*", "", x) == ""
}

# Given a d3-format list and the name of an item in each sublist, return a
# vector containing the corresponding item from each sublist. If the value is
# not present or NULL, it will be filled in with NA.
extract_vector <- function(x, name) {
  vecs <- lapply(x, function(y) {
    value <- y[[name]]
    if (is.null(value)) value <- NA
    value
  })
  do.call(c, vecs)
}

# Convert d3-format nested list to data frame. The column names must be
# supplied by the caller.
d3_to_df <- function(x, colnames) {
  names(colnames) <- colnames
  res <- lapply(colnames, function(colname) extract_vector(x, colname))
  as.data.frame(res, stringsAsFactors = FALSE)
}

set_options <- function(new_options) {
  do.call(options, as.list(new_options))
}
#' Eval with Options
#'
#' @export
#' @param new_options list of options to be supplied to `options()`
#' @param code code to evaluate, given the new options
#' @examples
#' \dontrun{with_options(list(warn = 0), {
#'   warning('just a warning')
#'   with_options(list(warn = 2), { warning('made into error') })
#'   warning('just a warning')
#' })}
with_options <- function(new_options, code) {
  old_options <- set_options(new_options)
  on.exit({
    set_options(old_options)
  })

  force(code)
}

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
#' @param ci_repo The shinycoreci repo to create the event on; defaults to
#'   rstudio/shinycoreci
#' @param apps_repo The shinycoreci-apps repo to clone and test; defaults to
#'   rstudio/shinycoreci-apps
#' @param apps_repo_ref The ref (branch, tag, sha) of `apps_repo` to clone;
#'   defaults to master.
#' @param client_payload The JSON object to make available in the workflow as
#'   the `github.event.client_payload` object
#' @param auth_token Your GitHub OAuth2 token; defaults to
#'   `Sys.getenv("GITHUB_PAT")`
#'
#' @importFrom curl new_handle handle_setheaders handle_setopt curl_fetch_memory
#' @importFrom jsonlite toJSON
#' @export
trigger <- function(
  event_type,
  ci_repo = "rstudio/shinycoreci",
  apps_repo = "rstudio/shinycoreci-apps",
  apps_repo_ref = "master",
  client_payload = list(
    event_type = event_type,
    client_payload = list(
      apps_repo = apps_repo,
      apps_repo_ref = apps_repo_ref
    )
  ),
  auth_token = Sys.getenv("GITHUB_PAT")
) {
  h <- new_handle()
  handle_setheaders(h, .list = list(
    Authorization = sprintf("token %s", auth_token),
    Accept = "application/vnd.github.v3+json, application/vnd.github.everest-preview+json"
  ))
  handle_setopt(h, .list = list(
    postfields = toJSON(
      auto_unbox = TRUE,
      list(
        event_type = event_type,
        client_payload = client_payload
      )
    )
  ))
  url <- sprintf("https://api.github.com/repos/%s/dispatches", ci_repo)
  curl_fetch_memory(url, handle = h)
}

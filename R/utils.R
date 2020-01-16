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
}

triple_colon <- function(pkg, name) {
  getNamespace(pkg)[[name]]
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


#' @export
#' @description https://developer.github.com/v3/repos/#create-a-repository-dispatch-event
trigger <- function(
  event_type,
  ci_repo = "rstudio/shinycoreci",
  apps_repo = "rstudio/shinycoreci-apps",
  apps_repo_ref = "master",
  auth_token = Sys.getenv("GITHUB_PAT")
) {
  h <- curl::new_handle()
  handle_setheaders(h, .list = list(
    Authorization = sprintf("token %s", auth_token),
    Accept = "application/vnd.github.v3+json, application/vnd.github.everest-preview+json"
  ))
  handle_setopt(h, .list = list(
    postfields = jsonlite::toJSON(
      auto_unbox = TRUE,
      list(
        event_type = event_type,
        client_payload = list(
          apps_repo = apps_repo,
          apps_ref = apps_repo_ref
        )
      )
    )
  ))
  url <- sprintf("https://api.github.com/repos/%s/dispatches", ci_repo)
  curl_fetch_memory(url, handle = h)
}

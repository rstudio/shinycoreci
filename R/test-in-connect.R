
#' Test deployed apps
#'
#' Opens an app on the hosted server and runs silbing apps in an iframe.
#'
#' @export
#' @describeIn test_in_deployed Test deployed applications on RStudio Connect
#' @param type Type of apps to test. `"manual"` (default) will only contain apps
#' that should be manually tested. `"all"` will contain all apps that have
#' been deployed. This is every app except for `141-radiant`.
#' @examples
#' \dontrun{test_in_connect()}
test_in_connect <- function(type = c("manual", "all")) {

  type <- match.arg(type)
  app_url <- switch(type,
    "manual" = default_connect_urls[["000-manual"]],
    default_connect_urls[["000-all"]]
  )

  utils::browseURL(app_url)
}


#' Locally test deployed apps
#'
#' Automatically runs the next app in a fresh callr::r_bg session.  To stop, close the shiny application window.
#'
#' @inheritParams test_in_browser
#' @param urls Named vector of urls to visit. This should be the output of `[connect_urls]`. By default this will set `server`, `account`, `dir`, and `apps`
#' @param server,account Parameters that could be supplied to `[rsconnect::deployApp]`
#' @param host `host` for the foreground app processes
#' @noRd
## Used in `./inst/apps/{000-manual, 000-all}`
test_in_connect_app <- function(
  app_name = apps[1],
  apps = apps_manual,
  ...,
  urls = default_connect_urls,
  server = attr(urls, "server"),
  account = attr(urls, "account"),
  port = NULL,
  host = NULL
) {
  server <- force(server)
  account <- force(account)
  apps <- resolve_app_name(apps)

  urls <- urls[unname(apps)]
  apps_not_deployed <- setdiff(names(urls), apps_deploy)
  if (length(apps_not_deployed) > 0) {
    message("Some apps are not found! Removing:")
    utils::str(as.list(apps_not_deployed))
    urls <- urls[setdiff(names(urls), apps_not_deployed)]
  }

  app_infos <- mapply(urls, names(urls), SIMPLIFY = FALSE, FUN = function(url, app_name) {
    list(
      app_name = app_name,
      start = function() { invisible(TRUE) },
      on_session_ended = function() { invisible(TRUE) },
      output_lines = function(reset = FALSE) {
        url
      },
      app_url = function() {
        url
      },
      # user_agent = function(user_agent) {
      #   app_status_user_agent_browser(user_agent, gsub("[^a-z]", "", server))
      # },
      header = function() {
        shiny::tagList(shiny::tags$strong(server, ": "), shiny::tags$code(account))
      }
    )
  })

  test_in_external(
    app_infos = app_infos,
    default_app_name = app_name,
    host = host,
    port = port
  )
}

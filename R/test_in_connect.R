
#' Test deployed apps
#'
#' Automatically runs the next app in a fresh callr::r_bg session.  To stop, close the shiny application window.
#'
#' @inheritParams test_in_browser
#' @param urls Named vector of urls to visit. By default this is determined using the `server`, `account`, `dir`, and `apps`
#' @param server,account Parameters that could be supplied to `[rsconnect::deployApp]`
#' @export
#' @describeIn test_in_deployed Test connect applications given the server and account
#' @examples
#' \dontrun{test_in_connect(dir = "apps")}
test_in_connect <- function(
  dir = "apps",
  server = "beta.rstudioconnect.com",
  account = "barret",
  apps = basename(apps_deploy(dir)),
  urls = connect_urls(
    dir,
    apps = apps,
    account = account,
    server = server
  ),
  app = basename(apps)[1],
  port = 8080,
  host = "127.0.0.1"
) {

  app <- normalize_app_name(dir, apps, app, increment = FALSE)

  app_names <- names(urls)

  app_infos <- mapply(urls, app_names, SIMPLIFY = FALSE, FUN = function(url, app_name) {
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
      user_agent = function(user_agent) {
        paste0(gsub("[^a-z]", "", server), "_", app_status_user_agent_browser(user_agent))
      },
      header = function() {
        shiny::tagList(shiny::tags$strong(server, ": "), shiny::tags$code(account))
      }
    )
  })

  test_in_external(
    dir = dir,
    app_infos = app_infos,
    app = app,
    host = host,
    port = port
  )
}


test_in_connect_script <- function(
  dir = "apps",
  server = "beta.rstudioconnect.com",
  account = "barret",
  apps = basename(apps_deploy(dir)),
  app = basename(apps)[1],
  port = 8080,
  host = "127.0.0.1",
  urls = connect_urls(dir = dir, apps = apps, account = account, server = server)
) {
  sys_call <- match.call()

  sys_call_list <- as.list(sys_call)
  sys_call_list[[1]] <- substitute(shinycoreci::test_in_connect)
  sys_call_list$dir <- dir
  sys_call_list$server <- server
  sys_call_list$account <- account
  sys_call_list$port <- port
  sys_call_list$host <- host
  sys_call_list$urls <- urls
  sys_call <- as.call(sys_call_list)


  sys_call
}

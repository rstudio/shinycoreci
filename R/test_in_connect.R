
#' Test deployed apps
#'
#' Automatically runs the next app in a fresh callr::r_bg session.  To stop, close the shiny application window.
#'
#' @inheritParams test_in_browser
#' @param urls Named vector of urls to visit. This should be the output of `[connect_urls]`. By default this is determined using the `server`, `account`, `dir`, and `apps`
#' @param server,account Parameters that could be supplied to `[rsconnect::deployApp]`
#' @export
#' @describeIn test_in_deployed Test connect applications given the server and account
#' @examples
#' \dontrun{test_in_connect(dir = "apps")}
test_in_connect <- function(
  dir = "apps",
  urls = test_in_connect_urls(),
  apps = names(urls),
  app = apps[1],
  server = attr(urls, "server"),
  account = attr(urls, "account"),
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


generate_test_in_connect_urls <- function(
  save_file = "R/zzz-test_in_connect_urls.R",
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

  cat(
    file = save_file,
    paste0(
      "test_in_connect_urls <- function() {\n",
      paste0(capture.output({dput(urls)}), collapse = "\n"), "\n",
      "}\n"
    )
  )
  message("Saved ", length(urls), " urls to: ", save_file)
}

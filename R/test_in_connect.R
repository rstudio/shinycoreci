
#' Test deployed apps
#'
#' Automatically runs the next app in a fresh callr::r_bg session.  To stop, close the shiny application window.
#'
#' @inheritParams test_in_browser
#' @param urls Named vector of urls to visit. This should be the output of `[connect_urls]`. By default this will set `server`, `account`, `dir`, and `apps`
#' @param server,account Parameters that could be supplied to `[rsconnect::deployApp]`
#' @export
#' @describeIn test_in_deployed Test connect applications given the server and account
#' @examples
#' \dontrun{test_in_connect(dir = "apps")}
test_in_connect <- function(
  dir = "apps",
  urls = connect_urls_cache(dir = dir, apps = apps, account = "barret", server = "beta.rstudioconnect.com"),
  server = attr(urls, "server"),
  account = attr(urls, "account"),
  apps = apps_manual(dir),
  app = apps[1],
  port = 8080,
  host = "127.0.0.1"
) {
  req_core_pkgs()

  server <- force(server)
  account <- force(account)

  apps_not_deployed <- setdiff(apps, names(urls))
  if (length(apps_not_deployed) > 0) {
    message("Some apps are not found! Removing:")
    utils::str(as.list(apps_not_deployed))
    apps <- setdiff(apps, apps_not_deployed)
  }

  urls <- urls[apps]

  app_infos <- mapply(urls, apps, SIMPLIFY = FALSE, FUN = function(url, app_name) {
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
        app_status_user_agent_browser(user_agent, gsub("[^a-z]", "", server))
      },
      header = function() {
        shiny::tagList(shiny::tags$strong(server, ": "), shiny::tags$code(account))
      }
    )
  })

  test_in_external(
    dir = dir,
    app_infos = app_infos,
    app = normalize_app_name(apps, app, increment = FALSE),
    host = host,
    port = port
  )
}


#' @export
#' @describeIn test_in_deployed Save connect urls as they can not be retrieved by everyone at run time
#' @param save_file location to save the file
#' @param urls urls to be supplied by `connect_urls` output
connect_urls_cache_save <- function(
  dir = "apps",
  apps = apps_deploy(dir),
  server = "beta.rstudioconnect.com",
  account = "barret",
  save_file = connect_urls_cache_file(dir = dir, account = account, server = server),
  urls = connect_urls(dir = dir, apps = apps, account = account, server = server)
) {
  if (!dir.exists(dirname(save_file))) {
    dir.create(dirname(save_file), recursive = TRUE)
  }
  dput(urls, file = save_file)
  message("Saved ", length(urls), " urls to: ", save_file)
}


#' @export
#' @describeIn test_in_deployed Get cached connect url information or retrieve them from server
connect_urls_cache_file <- function(dir, account, server) {
  file.path(dirname(dir), "zzz_shinycoreci", "connect", paste0(
    "urls_", tolower(gsub("[^a-z]", "", server)), "_", tolower(gsub("[^a-z]", "", account)), ".R"
  ))
}

#' @export
#' @describeIn test_in_deployed Get cached connect url information or retrieve them from server
connect_urls_cache <- function(dir = "apps", apps = apps_deploy(dir), account = "barret", server = "beta.rstudioconnect.com") {
  connect_urls_filename <- connect_urls_cache_file(dir = dir, account = account, server = server)
  if (file.exists(connect_urls_filename)) {
    dget(connect_urls_filename)
  } else {
    connect_urls(dir = dir, apps = apps, account = account, server = server)
  }
}

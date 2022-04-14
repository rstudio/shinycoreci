#' @export
#' @describeIn test_in_deployed Test connect applications given the server and account
#' @examples
#' \dontrun{test_in_test_in_shinyapps_io(dir = "apps")}
test_in_shinyappsio <- function(
  app_name = apps[1],
  apps = apps_manual,
  port = 8080,
  host = "127.0.0.1",
  account = "testing-apps",
  server = "shinyapps.io"
) {

  apps <- resolve_app_name(apps)

  urls <- lapply(apps, function(app_name) {
    paste0("http://", account, ".", server, "/", app_name)
  })
  names(urls) <- apps

  test_in_connect(
    apps = apps,
    urls = urls,
    account = account,
    server = server,
    app_name = app_name,
    host = host,
    port = port
  )
}

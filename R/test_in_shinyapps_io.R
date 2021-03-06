#' @export
#' @describeIn test_in_deployed Test connect applications given the server and account
#' @examples
#' \dontrun{test_in_test_in_shinyapps_io(dir = "apps")}
test_in_shinyappsio <- function(
  dir = "apps",
  apps = apps_manual(dir),
  app = apps[1],
  port = 8080,
  host = "127.0.0.1",
  account = "testing-apps",
  server = "shinyapps.io"
) {

  app_names <- basename(apps)
  urls <- lapply(app_names, function(app_name) {
    paste0("http://", account, ".", server, "/", app_name)
  })
  names(urls) <- app_names

  test_in_connect(
    dir = dir,
    apps = apps,
    account = account,
    server = server,
    urls = urls,
    app = normalize_app_name(apps, app, increment = FALSE),
    host = host,
    port = port
  )
}

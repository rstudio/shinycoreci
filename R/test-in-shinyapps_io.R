#' @export
#' @describeIn test_in_deployed Test connect applications given the server and account
#' @examples
#' \dontrun{test_in_test_in_shinyapps_io()}
test_in_shinyappsio <- function(type = c("manual", "all")) {

  type <- match.arg(type)
  app_url <- switch(type,
    "manual" = "https://testing-apps.shinyapps.io/000-manual/",
    "https://testing-apps.shinyapps.io/000-all/"
  )

  browseURL(app_url)
}


## Used in `./inst/apps/{000-manual, 000-all}`
test_in_shinyappsio_app <- function(
  app_name = apps[1],
  apps = apps_manual,
  port = 8080,
  host = "127.0.0.1",
  account = "testing-apps",
  server = "shinyapps.io"
) {

  apps <- resolve_app_name(apps)

  urls <- lapply(apps, function(app_name) {
    paste0("https://", account, ".", server, "/", app_name)
  })
  names(urls) <- apps

  test_in_connect_app(
    apps = apps,
    urls = urls,
    account = account,
    server = server,
    app_name = app_name,
    host = host,
    port = port
  )
}

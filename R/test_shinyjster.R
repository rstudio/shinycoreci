#' Test shinyjster
#'
#' @inheritParams shinyjster::run_headless
#' @export
test_shinyjster <- function(
  apps = file.path('apps', apps_shinyjster()),
  port = 8000,
  host = "127.0.0.1",
  debug_port = NULL,
  browser = c("chrome", "firefox"),
  type = c("serial", "lapply", "parallel", "callr"),
  assert = TRUE
) {
  shinyjster::run_headless(
    apps = apps,
    port = port,
    host = host,
    debug_port = debug_port,
    browser = match.arg(browser),
    type = match.arg(type),
    assert = assert
  )
}

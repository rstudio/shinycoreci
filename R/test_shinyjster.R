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

  ras <- regular_and_source_apps(apps, "_shinyjster.R")

  regular_dt <- NULL
  source_dt <- NULL

  if (length(ras$regular) > 0) {
    regular_dt <-
      shinyjster::run_headless(
        apps = ras$regular,
        port = port,
        host = host,
        debug_port = debug_port,
        browser = match.arg(browser),
        type = match.arg(type),
        assert = FALSE
      )
    regular_dt <- cbind(regular_dt, kind = "shiny", stringsAsFactors = FALSE)
  }

  if (length(ras$source) > 0) {
    source_dt <-
      test_shinyjster_source(
        apps = ras$source,
        args = list(
          assert = FALSE,
          type = "serial",
          port = port,
          host = host,
          debug_port = debug_port
        )
      )
    source_dt <- cbind(source_dt, kind = "source", stringsAsFactors = FALSE)
  }

  ret <- rbind(regular_dt, source_dt, stringsAsFactors = FALSE)

  # reorder rows to match original order
  appDir <- ret$appDir
  order <- vapply(apps, function(app) { which(app == appDir) }, numeric(1))
  ret[order, ]
}

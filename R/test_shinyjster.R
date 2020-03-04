#' Test shinyjster
#'
#' @param dir base folder to look for applications
#' @param apps applications within \verb{dir} to run
#' @inheritParams shinyjster::run_headless
#' @export
test_shinyjster <- function(
  dir = "apps",
  apps = apps_shinyjster(dir),
  port = 8000,
  host = "127.0.0.1",
  debug_port = NULL,
  browser = c("chrome", "firefox"),
  type = c("serial", "lapply", "parallel", "callr"),
  assert = TRUE
) {

  ras <- regular_and_source_apps(file.path(dir, apps), "_shinyjster.R")

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

  if (isTRUE(assert)) {
    shinyjster::assert_jster(ret)
  } else {
    ret
  }
}

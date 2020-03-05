#' Test shinyjster
#'
#' @param dir base folder to look for applications
#' @param apps applications within \verb{dir} to run
#' @param assert Logical value which will determine if \code{shinyjster::assert_jster} will be run on the final output. Defaults to \code{TRUE}
#' @inheritParams shinyjster::run_jster_apps
#' @export
test_shinyjster <- function(
  dir = "apps",
  apps = apps_shinyjster(dir),
  port = 8000,
  host = "127.0.0.1",
  browser = "chrome",
  type = c("serial", "lapply", "parallel", "callr"),
  assert = TRUE
) {

  if (is.character(browser) && length(browser) == 1) {
    browser <- switch(browser,
      "chrome" = shinyjster::selenium_chrome(headless = TRUE),
      "firefox" = shinyjster::selenium_chrome(headless = TRUE),
      "edge" = shinyjster::selenium_edge(),
      "ie" = shinyjster::selenium_ie(),
      browser
    )
  }

  ras <- regular_and_source_apps(file.path(dir, apps), "_shinyjster.R")

  regular_dt <- NULL
  source_dt <- NULL

  if (length(ras$regular) > 0) {
    regular_dt <-
      shinyjster::run_jster_apps(
        apps = ras$regular,
        port = port,
        host = host,
        browser = browser,
        type = match.arg(type)
      )
    regular_dt <- cbind(regular_dt, kind = "shiny", stringsAsFactors = FALSE)
  }

  if (length(ras$source) > 0) {
    source_dt <-
      test_shinyjster_source(
        apps = ras$source,
        args = list(
          port = port,
          host = host,
          browser = browser
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

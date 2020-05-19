
#' Test shinyjster app
#'
#' Method to avoid editing MANY different files to do the same default behavior of `shinyjster::test_jster(browsers = selenium_chrome(), type = "lapply")`.
#'
#' Some extra logic wraps around whether or not a browser is available on the given platform.
#'
#' @inheritParams shinyjster::selenium_chrome
#' @param name browser name to use to determine the browser_func
#' @param browser_func One of `c("chrome", "firefox", "edge", "ie")`. If an unknown `browser_name` is used, `browser_func` will default to using `chrome`.
#' @param apps shiny app to be tested using shinyjster
#' @seealso [test_shinytest_app()] and [test_runtests()]
#' @export
test_shinyjster_app <- function(
  name,
  browser_func = switch(
    name,
    chrome = shinyjster::selenium_chrome(timeout = timeout, dimensions = dimensions),
    firefox = shinyjster::selenium_firefox(timeout = timeout, dimensions = dimensions),
    edge = shinyjster::selenium_edge(timeout = timeout, dimensions = dimensions),
    ie = shinyjster::selenium_ie(timeout = timeout, dimensions = dimensions),
    {
      message("unknown browser name supplied. Using 'chrome'")
      shinyjster::selenium_chrome()
    }
  ),
  apps = "..",
  timeout = 2 * 60,
  dimensions = "1200x1200"
) {

  browser_name_val <- attr(browser_func, "browser")
  if (length(browser_name_val) == 0) {
    stop("Could not find `browser` attribute from `browser_func`")
  }

  # do not test on edge
  if (browser_name_val %in% "edge") {
    # return NULL to signify that no test was done
    return(NULL)
  }

  if (browser_name_val %in% c("edge", "ie")) {
    if (platform() != "win") {
      # return NULL to signify that no test was done
      return(NULL)
    }
  }

  shinyjster::test_jster(apps = apps, browsers = browser_func, type = "lapply")
}




#' Test shinytest app
#'
#' @inheritParams shinytest::testApp
#' @seealso [test_shinyjster_app()], [test_runtests()], and [platform_rversion()]
#' @export
test_shinytest_app <- function(
  appDir = "..",
  suffix = platform_rversion()
) {
  base__library("shinytest", character.only = TRUE)

  shinytest::expect_pass(
    shinytest::testApp(
      appDir,
      suffix = suffix
    )
  )
}

#' Platform and R Version
#'
#' @param platform_val See [platform()]
#' @param r_version See [r_version_short()]
#' @export
platform_rversion <- function(platform_val = platform(), r_version = r_version_short()) {
  paste0(platform_val, "-", r_version)
}

#' Test shinytest app
#'
#' @seealso [test_shinyjster_app()] and [test_runtests()]
#' @export
test_testhat_app <- function() {
  base__library("testthat", character.only = TRUE)

  testthat::test_dir(
    "./testthat",
    # Run in the app's environment containing all support methods.
    env = shiny::loadSupport(),
    # Display the regular progress output and throw an error if any test error is found
    reporter = c("progress", "fail")
  )

}

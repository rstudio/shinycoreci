
#' Test shinyjster app
#'
#' Method to avoid editing MANY different files to do the same default behavior of `shinyjster::test_jster(browsers = selenium_chrome(), type = "lapply")`.
#'
#' Some extra logic wraps around whether or not a browser is available on the given platform.
#'
#' @param name browser name to use to determine the browser_func
#' @param browser_func One of `c("chrome", "firefox", "edge", "ie")`. If an unknown `browser_name` is used, `browser_func` will default to using `chrome`.
#' @param apps shiny app to be tested using shinyjster
#' @seealso [test_shinytest_app()] and [test_runtests()]
#' @export
test_shinyjster_app <- function(
  name,
  browser_func = switch(
    name,
    chrome = shinyjster::selenium_chrome(),
    firefox = shinyjster::selenium_firefox(),
    edge = shinyjster::selenium_edge(),
    ie = shinyjster::selenium_ie(),
    {
      message("unknown browser name supplied. Using 'chrome'")
      shinyjster::selenium_chrome()
    }
  ),
  apps = ".."
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
#' @seealso [test_shinyjster_app()] and [test_runtests()]
#' @export
test_shinytest_app <- function(
  appDir = "..",
  suffix = shinycoreci::platform()
) {
  base__library("shinytest", character.only = TRUE)

  shinytest::expect_pass(
    shinytest::testApp(
      appDir,
      suffix = suffix
    )
  )
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

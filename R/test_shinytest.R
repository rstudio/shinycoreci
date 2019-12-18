#' Test shinytest
#'
#' @param apps Character vector of shiny applications
#' @param dir Name of directory to look for shiny apps, and to save platform
#'   information.
#' @inheritParams shinytest::testApp
#' @export
#' @import shinytest
test_shinytest <- function(
  dir = ".",
  apps = apps_shinytest(),
  suffix = platform()
) {
  # Record platform info and package versions
  write_sysinfo(file.path(dir, paste0("sysinfo-", suffix, ".txt")))

  appdirs <- file.path(dir, apps_shinytest())

  for (appdir in appdirs) {
    message("Testing ", appdir)
    expect_pass(testApp(appdir, suffix = suffix))
  }
}

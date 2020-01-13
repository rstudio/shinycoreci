#' Test shinytest
#'
#' @param apps Character vector of shiny applications
#' @param dir Name of directory to look for shiny apps, and to save platform
#'   information.
#' @inheritParams shinytest::testApp
#' @export
test_shinytest <- function(
  dir = ".",
  apps = apps_shinytest(),
  suffix = platform()
) {
  # Record platform info and package versions
  write_sysinfo(file.path(dir, paste0("sysinfo-", suffix, ".txt")))

  appdirs <- file.path(dir, apps)

  for (appdir in appdirs) {
    message("Testing ", appdir)
    shinytest::expect_pass(shinytest::testApp(appdir, suffix = suffix))
  }
}

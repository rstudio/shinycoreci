#' Test shinytest
#'
#' @param apps Character vector of shiny applications
#' @param dir Name of directory to look for shiny apps, and to save platform
#'   information.
#' @inheritParams shinytest::testApp
#' @export
#' @import shinytest
test_shinytest <- function(
  apps = list.dirs(dir, recursive = FALSE),
  dir = ".",
  suffix = platform()
) {
  # Record platform info and package versions
  write_sysinfo(file.path(dir, paste0("sysinfo-", suffix, ".txt")))

  for (appdir in apps) {
    message("Testing ", appdir)
    expect_pass(testApp(appdir, suffix = suffix))
  }
}

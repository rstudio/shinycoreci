#' Test shinytest
#'
#' @param apps Character vector of shiny applications
#' @param dir Name of directory to look for shiny apps, and to save platform
#'   information.
#' @inheritParams shinytest::testApp
#' @export
test_shinytest <- function(
  dir = "apps",
  apps = apps_shinytest(dir),
  suffix = platform()
) {
  # Record platform info and package versions
  write_sysinfo(file.path(dir, paste0("sysinfo-", suffix, ".txt")))

  appdirs <- file.path(dir, apps)

  fail_apps <- character(0)
  for (appdir in appdirs) {
    message("Testing ", appdir)
    tryCatch(
      shinytest::expect_pass(shinytest::testApp(appdir, suffix = suffix)),
      error = function(failed) {
        message("Failed: ", failed$message)
        fail_apps <<- c(fail_apps, basename(appdir))
      }
    )
  }

  if (length(fail_apps) > 0) {
    stop("Apps failed tests: ", paste(fail_apps, collapse = ", "))
  }

}

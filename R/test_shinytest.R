
#' Test shinytest
#'
#' @param apps Character vector of shiny applications
#' @inheritParams shinytest::testApp
#' @export
#' @import shinytest
test_shinytest <- function(apps = list.dirs("apps", recursive = FALSE), suffix = platform()) {
  # Record platform info and package versions
  cat(utils::capture.output(print(R.version)), sep = "\n", file = "apps/r_version.txt")
  # Call it renv.txt instead of renv.lock, because we just want it to be a log
  # of the packages, not an actual lock file.
  renv::snapshot(getwd(), lockfile = "apps/renv.txt", confirm = FALSE)
  # The renv/ dir is created by snapshot(), but we don't need it.
  rm_files(c(
    file.path(getwd(), "renv", "activate.R"),
    file.path(getwd(), "renv")
  ))

  for (appdir in apps) {
    message("Testing ", appdir)
    expect_pass(testApp(appdir, suffix = suffix))
  }
}

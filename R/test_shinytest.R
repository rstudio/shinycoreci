is_windows <- function() .Platform$OS.type == "windows"
is_mac     <- function() Sys.info()[["sysname"]] == "Darwin"
is_linux   <- function() Sys.info()[["sysname"]] == "Linux"

platform <- function() {
  if (is_windows()) return("win")
  if (is_mac())     return("mac")
  if (is_linux())   return("linux")
}


# Remove files, but only try to remove if they exist (so we don't get
# warnings).
rm_files <- function(filenames) {
  # Only try to remove files that actually exist
  filenames <- filenames[file.exists(filenames)]
  file.remove(filenames)
}


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

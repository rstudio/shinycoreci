
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
#' @inheritParams shinytest::testApp
#' @export
#' @import shinytest
test_shinytest <- function(apps = list.dirs(".", recursive = FALSE), suffix = platform()) {
  # Record platform info and package versions
  cat(
    capture.output(print(R.version)), sep = "\n",
    file = paste0("rversion-", suffix, ".txt")
  )
  # Call it renv-mac.json instead of renv.lock, because we just want it to be a
  # log of the packages, not an actual lock file.
  renv::snapshot(getwd(), lockfile = paste0("renv-", suffix, ".json"), confirm = FALSE)
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


# test_shinytest()

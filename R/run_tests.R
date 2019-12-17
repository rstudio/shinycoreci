library(shinytest)

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


test_shinytest <- function(apps = list.dirs("apps", recursive = FALSE), suffix = platform()) {
  # Record platform info and package versions
  cat(capture.output(print(R.version)), sep = "\n", file = "apps/r_version.txt")
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


# test_shinytest()

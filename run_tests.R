library(shinytest)

is_windows <- function() .Platform$OS.type == "windows"
is_mac     <- function() Sys.info()[["sysname"]] == "Darwin"
is_linux   <- function() Sys.info()[["sysname"]] == "Linux"

platform <- function() {
  if (is_windows()) return("win")
  if (is_mac())     return("mac")
  if (is_linux())   return("linux")
}



test_apps <- function(suffix = platform()) {
  appdirs <- file.path("apps", dir("apps"))
  for (appdir in appdirs) {
    message("Testing ", appdir)
    expect_pass(testApp(appdir, suffix = suffix))
  }
}


test_apps()

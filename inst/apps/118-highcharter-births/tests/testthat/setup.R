# Load application support files into testing environment
shinytest2::load_app_env()

skip_if_not_macos <- function() {
    if (Sys.info()[["sysname"]] != "Darwin") {
        testthat::skip("Test only runs on macOS")
    }
}

skip_if_not_linux_or_windows <- function() {
    if (Sys.info()[["sysname"]] == "Darwin") {
        testthat::skip("Test only runs on Linux or Windows")
    }
}

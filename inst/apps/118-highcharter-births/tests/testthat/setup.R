# Load application support files into testing environment
shinytest2::load_app_env()

get_platform <- function() {
    sysname <- Sys.info()[["sysname"]]
    switch(
        sysname,
        "Darwin" = "macos",
        "Linux" = "linux",
        "Windows" = "windows",
        "unknown"
    )
}

skip_on_platform <- function(platforms, reason = NULL) {
    current_platform <- get_platform()
    platforms <- tolower(as.character(platforms))

    if (current_platform %in% platforms) {
        reason <- reason %||%
            paste("Test skipped on", paste(platforms, collapse = ", "))
        testthat::skip(reason)
    }
}

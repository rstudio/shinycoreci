find_bad_shinytest_files <- function(path = ".") {

  folders <- strsplit(
    dir(path, , pattern = "-current", recursive = TRUE, include.dirs = TRUE),
    .Platform$file.sep
  )
  folder_names <- unique(vapply(folders, `[[`, character(1), 1))
  folder_names
}

bad_shinytest_platform <- function() {
  branch <- system("git rev-parse --abbrev-ref HEAD", intern = TRUE)

  system_val <- strsplit(branch, "-")[[1]]
  switch(
    system_val[[length(system_val)]],
    "macOS" = "mac",
    "Windows" = "win",
    "Linux" = "linux",
    stop("unknown system type for branch: ", branch)
  )
}


#' View Shinytest Diff
#'
#' @param suffix Test output suffix to compare against
#' @param path Root folder path
#' @param ... Extra arguments passed to `shinytest::viewTestDiff`
#' @export
view_test_diff <- function(suffix = c("win", "mac", "linux"), path = "apps", ...) {
  if (missing(suffix)) {
    suffix <- bad_shinytest_platform()
  }
  suffix <- match.arg(suffix)

  folders <- find_bad_shinytest_files(path)

  if (length(folders) == 0) {
    stop("No app folders to view")
  }

  if (length(folders) > 1) {
    ans <- utils::menu(c("(All apps)", folders), graphics = FALSE, title = "Select the app folder to view shinytest diff")
    # ans = 0; all
    # ans = 1; all
    if (ans > 1) {
      # if ans is not 'all', subset the folders
      ans_pos <- ans - 1
      folders <- folders[ans_pos]
    }
  }

  lapply(file.path(path, folders), function(folder) {
    # pause between apps for a second and let later clear out what is executing.
    # https://github.com/rstudio/shiny/issues/2743
    for(i in 1:10) {
      later::run_now()
    }

    ans <- shinytest::viewTestDiff(appDir = folder, suffix = suffix, interactive = TRUE, ...)
    ans
  })
}

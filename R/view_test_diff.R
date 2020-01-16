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
    stop("unknown system type for branch: ", branch)
  )
}


#' View Shinytest Diff
#'
#' @param suffix Test output suffix to compare against
#' @param path Root folder path
#' @param ... Extra arguments passed to `shinytest::viewTestDiff`
#' @export
view_test_diff <- function(suffix = c("win", "mac"), path = ".", ...) {
  if (missing(suffix)) {
    suffix <- bad_shinytest_platform()
  }
  suffix <- match.arg(suffix)

  folders <- find_bad_shinytest_files(path)
  for (folder in folders) {
    shinytest::viewTestDiff(folder, suffix = suffix, ...)
  }
}

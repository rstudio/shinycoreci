find_bad_shinytest_files <- function(dir = ".") {

  folders <- strsplit(
    shinytest_current_folder(dir),
    .Platform$file.sep
  )
  folder_names <- unique(vapply(folders, `[[`, character(1), 1))
  folder_names
}

bad_shinytest_suffix <- function(dir = "apps") {
  branch <- git_cmd(dir, "git rev-parse --abbrev-ref HEAD")
  if (!grepl("^gha-", branch)) {
    message("Not in an auto-generated git branch. Using local platform")
    return(platform_rversion())
  }

  shinytest_suffix(branch)
}

shinytest_suffix <- function(
  branch = git_cmd("apps", "git rev-parse --abbrev-ref HEAD")
) {

  system_val <- strsplit(branch, "-")[[1]]
  platform_val <- switch(
    system_val[[length(system_val)]],
    "macOS" = "mac",
    "Windows" = "win",
    "Linux" = "linux",
    stop("unknown system type for branch: ", branch)
  )
  r_version <- system_val[[length(system_val) - 1]]
  platform_rversion(platform_val, r_version)
}


#' View Shinytest Diff
#'
#' @param suffix Test output suffix to compare against
#' @param dir Root folder path
#' @param ... Extra arguments passed to `shinytest::viewTestDiff`
#' @export
view_test_diff <- function(suffix = platform_rversion(), dir = "apps", ...) {
  validate_core_pkgs()

  if (missing(suffix)) {
    suffix <- bad_shinytest_suffix()
  }

  folders <- find_bad_shinytest_files(dir)

  if (length(folders) == 0) {
    message("Didn't detect any differences in shinytest baselines")
    return(invisible())
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

  lapply(file.path(dir, folders), function(folder) {
    shinytest__view_test_diff(appDir = folder, suffix = suffix, interactive = TRUE, ...)
  })
}


shinytest__view_test_diff <- function(...) {
  # pause between apps for a second and let later clear out what is executing.
  # https://github.com/rstudio/shiny/issues/2743
  for(i in 1:10) {
    later::run_now()
  }

  shinytest::viewTestDiff(...)
}

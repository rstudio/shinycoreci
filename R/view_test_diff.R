
shinytest_current_folder <- function(app_dir, pattern = "-current$") {
  dir(app_dir, , pattern = pattern, recursive = TRUE, include.dirs = TRUE)
}
shinytest_expected_no_suffix_folder <- function(app_dir) {
  shinytest_current_folder(app_dir, pattern = "-expected$")
}

find_bad_shinytest_files <- function(dir = ".") {

  folders <- strsplit(
    shinytest_current_folder(dir),
    .Platform$file.sep
  )
  # get all app folders and test names
  folders_info <- lapply(folders, function(folder) {
    list(
      app = folder[1],
      testname = sub(x = folder[4], "-current$", ""),
      path = paste0(folder, collapse = .Platform$file.sep)
    )
  })
  folders_info
}
shinytest_current_names <- function(folders_info) {
  vapply(folders_info, function(folder_info) {
    paste0(folder_info$app, " : ", folder_info$testname)
  }, character(1))
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
  stop("TODO-barret;")
  validate_core_pkgs()

  if (missing(suffix)) {
    suffix <- bad_shinytest_suffix()
  }

  folders_info <- find_bad_shinytest_files(dir)

  if (length(folders_info) == 0) {
    message("Didn't detect any differences in shinytest baselines")
    return(invisible())
  }

  if (length(folders_info) > 1) {
    ans <- utils::menu(
      c("(All apps)",
      shinytest_current_names(folders_info)),
      graphics = FALSE,
      title = "Select the app folder to view shinytest diff"
    )
    # ans = 0; all
    # ans = 1; all
    if (ans > 1) {
      # if ans is not 'all', subset the folders
      ans_pos <- ans - 1
      folders_info <- folders_info[ans_pos]
    }
  }

  lapply(folders_info, function(folder_info) {
    folder <- file.path(dir, folders_info$app)
    testname <- folders_info$testname
    shinytest__view_test_diff(appDir = folder, suffix = suffix, interactive = TRUE, testnames = testname, ...)
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

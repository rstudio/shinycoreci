#' View (and save) `test_in_local()` output
#'
#' Use `view_test_results()` to preview test results generated by `save_test_results()`
#' (saving should only ever be done in a GHA workflow).
#'
#' @param output output from `test_in_local()`.
#' @param gha_branch_name an identifier determined by the GHA workflow
#' @param pr_number the pull request number.
#' @param username the username of the github profile.
#' @inheritParams test_in_local
#' @rdname test-results
#' @export
save_test_results <- function(output, gha_branch_name, pr_number, username, repo_dir = rprojroot::find_package_root_file()) {
  if (!inherits(output, "shinycoreci_test_output")) {
    stop("`output` must be an object returned by test_in_local()", call. = FALSE)
  }
  repo_dir <- normalizePath(repo_dir, mustWork = TRUE)

  # The "result" is displayed as logs. Overwrite the result with the log value.
  # Remove the original log content
  # TODO-future - Should the result be removed if the status is "pass"?
  output$result <- output$log
  output$log <- NULL

  # Attach some other meta-data to the test results
  val <- list(
    results = output,
    platform = platform(),
    r_version = r_version_short(),
    session = unclass(sessioninfo::platform_info()),
    gha_image_version = gha_image_version(),
    sys_info = paste0(utils::capture.output({write_sysinfo()}), collapse = "\n"),
    branch_name = git_branch(repo_dir),
    branch_sha = git_sha(repo_dir),
    pr_number = pr_number,
    username = username,
    gha_branch_name = gha_branch_name,
    version = 2
  )

  # Where the results will be placed
  results_dir <- file.path(repo_dir, "__test_results")
  dir.create(results_dir, showWarnings = FALSE)
  results_file <- file.path(results_dir, paste0(gha_branch_name, ".json"))

  cat(jsonlite::toJSON(val, auto_unbox = TRUE), file = results_file)
  invisible(val)
}

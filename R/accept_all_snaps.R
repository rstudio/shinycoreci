#' Accept all snapshot changes
#'
#' Accepts **all** snapshot changes for every shiny application in `inst/apps`.
#'
#' @inheritParams fix_snaps
#' @export
accept_snaps <- function(
  repo_dir = "."
) {

  app_paths <- repo_apps_paths(repo_dir)

  pb <- progress_bar(
    total = length(app_paths),
    format = ":name [:bar] :current/:total"
  )

  for (app_path in app_paths) {
    pb$tick(tokens = list(name = basename(app_path)))
    withr::with_dir(app_path, {
      if (!dir.exists(file.path("tests/testthat/_snaps"))) next

      # Do not print if no changes are to be made
      snaps_info <- testthat__snapshot_meta()
      if (nrow(snaps_info) == 0) next

      cat("\n") # Fresh line for printing
      testthat::snapshot_accept()
    })
  }
}

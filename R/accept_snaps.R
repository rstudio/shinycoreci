#' Accept all snapshot changes
#'
#' Accepts **all** snapshot changes for every shiny application in `inst/apps`.
#'
#' @inheritParams fix_snaps
#' @export
accept_snaps <- function(
  repo_dir = rprojroot::find_package_root_file()
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


# Removes all snaps that are below the minimum R version
remove_snaps_cruft <- function(repo_dir = rprojroot::find_package_root_file(), min_r_version = "4.1") {
  app_paths <- repo_apps_paths(repo_dir)

  pb <- progress_bar(
    total = length(app_paths),
    format = ":name [:bar] :current/:total"
  )

  for (app_path in app_paths) {
    pb$tick(tokens = list(name = basename(app_path)))
    withr::with_dir(app_path, {
      if (!dir.exists(file.path("tests/testthat/_snaps"))) next

      snap_variants <- dir("tests/testthat/_snaps", full.names = TRUE)

      lapply(snap_variants, function(variant_folder) {
        if (!grepl("\\d\\.\\d$", basename(variant_folder))) {
          return()
        }
        r_version <- strsplit(basename(variant_folder), "-")[[1]][[2]]
        if (utils::compareVersion(r_version, min_r_version) == -1) {
          message(paste0("Removing ", variant_folder))
          unlink(variant_folder, recursive = TRUE)
        }
      })
    })
  }
}

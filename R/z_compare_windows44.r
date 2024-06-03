max_window44_diff <- function() {
  p <- progress::progress_bar$new(total = length(app_path_map), show_after = 0, clear = FALSE, format = ":spin :current/:total :eta | :app_path")

  diffs <-
    lapply(app_path_map, function(app_path) {
      p$tick(tokens = list(app_path = app_path))

      app_snaps_path <- file.path(app_path, "tests", "testthat", "_snaps")

      win44_path <- file.path(app_snaps_path, "windows-4.4")
      win43_path <- file.path(app_snaps_path, "windows-4.3")
      if (!dir.exists(win44_path)) {
        return(NULL)
      }
      if (!dir.exists(win43_path)) {
        message("\nNo snaps for windows-4.3 for app: ", app_path)
        return(NULL)
      }

      win44_files <- list.files(win44_path, full.names = TRUE, recursive = TRUE, pattern = "\\.png$")
      win43_files <- list.files(win43_path, full.names = TRUE, recursive = TRUE, pattern = "\\.png$")

      file_difference <- waldo::compare(
        win43_files,
        file.path(win43_path, basename(dirname(win44_files)), basename(win44_files))
      )
      if (length(file_difference) > 0) {
        message("\nDifferent snapshots for windows-4.4 and windows-4.3 for app: ", app_path, "\n", file_difference)
        return(NULL)
      }
      if (length(win44_files) == 0) {
        return(NULL)
      }

      return(Map(
        win44_files,
        win43_files,
        f = function(win44_file, win43_file) {
          tryCatch(
            {
              stop("Uncomment this code!")
              # shinytest2::screenshot_max_difference(win44_file, win43_file)
            },
            error = function(e) {
              message("\nError comparing ", win44_file, " and ", win43_file, ": ", e$message)
              return(1000)
            }
          )
        }
      ))
    })

  diffs <- diffs[!sapply(diffs, is.null)]

  diff_order <- order(unlist(lapply(diffs, function(diff) {
    max(unlist(diff))
  })), decreasing = TRUE)
  # browser()

  diffs[diff_order]
}

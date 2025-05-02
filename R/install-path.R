on_ci <- function() {
  isTRUE(as.logical(Sys.getenv("CI")))
}

#' Resolve library path
#' @param local_pkgs If `TRUE`, local packages will be used instead of the isolated shinyverse installation.
#' @keywords internal
resolve_libpath <- function(..., local_pkgs = FALSE) {
  stopifnot(length(list(...)) == 0)
  # If using local_pkgs, use the standard libpath location
  if (on_ci()) {
    # Notes 2025-05-02:
    # In https://github.com/schloerke/tmp-debug-gha-install/pull/2, we found that a custom libpath broke pak on windows.
    # Don't know why, but it did.
    # Related issue in pak: https://github.com/r-lib/pak/issues/762

    # To be consistent between platforms, we use the local libpath for when testing on CI
    # However, all installs will still be done within a callr process

    # If on CI, use the local libpath
    .libPaths()[1]
  } else {
    # If not on CI...

    if (isTRUE(local_pkgs)) {
      .libPaths()[1]
    } else {
      shinycoreci_libpath()
    }
  }
}


#' Shinyverse libpath
#'
#' Methods to get and reset the shinyverse `libpath`.
#'
#' @export
#' @describeIn shinycoreci_libpath Library path that will persist across installations. But will have a different path for different R versions
shinycoreci_libpath <- function() {
  # Dir location inspration from learnr:
  # https://github.com/rstudio/learnr/blob/1c01ac258230cbe217eee16c77cc71924faab1d3/R/storage.R#L275
  dir <- file.path(
    rappdirs::user_data_dir(),
    "R",
    "shinycoreci",
    paste0("R-", gsub(".", "_", getRversion(), fixed = TRUE))
  )
  # Provide a fully defined path. Things don't like to work without a fully defined path in pak
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
  }
  # Must normalize after creating the directory to avoid warning
  dir <- normalizePath(dir)
  dir
}
#' @export
#' @describeIn shinycoreci_libpath Removes the cached R library
shinycoreci_clean_libpaths <- function() {
  unlink(dirname(shinycoreci_libpath()), recursive = TRUE)
}

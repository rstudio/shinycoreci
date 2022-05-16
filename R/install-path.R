#' Shinyverse libpath
#'
#' Methods to get and reset the shinyverse `libpath`.
#'
#' @export
#' @describeIn shinyverse_libpath Library path that will persist across installations. But will have a different path for different R versions
shinyverse_libpath <- function() {
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
#' @describeIn shinyverse_libpath Removes the cached R library
shinyverse_clean_libpath <- function() {
  unlink(shinyverse_libpath(), recursive = TRUE)
}

#' @export
shinyverse_libpath <- function() {
  # Dir location inspration from learnr:
  # https://github.com/rstudio/learnr/blob/1c01ac258230cbe217eee16c77cc71924faab1d3/R/storage.R#L275
  dir <- file.path(
    rappdirs::user_data_dir(),
    "R",
    "shinycoreci",
    paste0("R-", version$major, "_", sub(".", "_", version$minor, fixed = TRUE))
  )
  # Provide a fully defined path. Things don't like to work without a fully defined path in pak
  dir <- normalizePath(dir)
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
  }
  dir
}
#' @export
shinyverse_clean_libpath <- function() {
  unlink(shinyverse_libpath(), recursive = TRUE)
}


#' Get names of Shiny apps to be tested
#'
#' All \code{apps_*} methods inspect each application to determine if if testing is possible.
#'
#' @rdname apps
#' @export
apps_shinytest <- function(dir) {
  files <- list.files(
    path = dir,
    pattern = "shinytest.R$",
    recursive = TRUE
  )
  dirname(dirname(files))
}


#' @rdname apps
#' @export
apps_shinyjster <- function(dir) {
  app_folders <- shiny_app_dirs(dir)
  calls_shinyjster <- vapply(app_folders, function(folder) {
    if (file.exists(file.path(folder, "_shinyjster.R"))) {
      return(TRUE)
    }

    app_or_ui_file <- dir(folder, pattern = "^(app|ui|server)|(.Rmd|.rmd)$", full.names = TRUE)[1]

    # if shinyjster appears in the file... success!
    any(grepl(
      "shinyjster",
      readLines(
        app_or_ui_file
      )
    ))
  }, logical(1))

  app_folders[calls_shinyjster]
}

#' @rdname apps
#' @export
apps_testthat <- function(dir) {
  files <- list.files(
    path = dir,
    pattern = "testthat.R$",
    recursive = TRUE
  )
  dirname(dirname(files))
}

#' @rdname apps
#' @export
apps_manual <- function(dir) {
  shiny_app_dirs(dir)
}


shiny_app_dirs <- function(dir) {
  list.dirs(dir, full.names = TRUE, recursive = FALSE)
}

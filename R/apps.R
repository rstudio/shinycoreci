
#' Get names of Shiny apps to be tested
#'
#' All \code{apps_*} methods inspect each application to determine if if testing is possible.
#'
#' @param dir base directory to look for shiny applications
#'
#' @describeIn app-folders App folders that contain a \verb{shinytest.R} file
#' @export
apps_shinytest <- function(dir) {
  files <- list.files(
    path = dir,
    pattern = "shinytest.R$",
    recursive = TRUE
  )
  dirname(dirname(files))
}


#' @describeIn app-folders App folders that contain the text \code{shinyjster} in a Shiny R file
#' @export
apps_shinyjster <- function(dir) {
  app_folders <- shiny_app_dirs(dir)
  calls_shinyjster <- vapply(app_folders, function(folder) {
    if (file.exists(file.path(folder, "_shinyjster.R"))) {
      return(TRUE)
    }

    app_or_ui_file <- shiny_app_files(folder)[1]

    # if shinyjster appears in the file... success!
    any(grepl(
      "shinyjster",
      readLines(app_or_ui_file)
    ))
  }, logical(1))

  app_folders[calls_shinyjster]
}

#' @describeIn app-folders App folders that contain a \verb{testthat.R} file
#' @export
apps_testthat <- function(dir) {
  files <- list.files(
    path = dir,
    pattern = "testthat.R$",
    recursive = TRUE
  )
  dirname(dirname(files))
}

#' @describeIn app-folders Any folder in the supplied \code{dir}
#' @export
apps_manual <- function(dir) {
  shiny_app_dirs(dir)
}

#' @describeIn app-folders App folders that contain a any Shiny app file
#' @export
apps_deploy <- function(dir) {
  app_folders <- shiny_app_dirs(dir)
  Filter(x = app_folders, function(app_folder) {
    return(
      length(shiny_app_files(app_folder)) > 0
    )
  })

}


shiny_app_dirs <- function(dir) {
  list.dirs(dir, full.names = TRUE, recursive = FALSE)
}
shiny_app_files <- function(app_folder) {
  dir(app_folder, pattern = "^(app|ui|server)|(.Rmd|.rmd)$", full.names = TRUE)
}

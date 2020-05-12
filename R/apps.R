
#' Get names of Shiny apps to be tested
#'
#' All \code{apps_*} methods inspect each application to determine if if testing is possible.
#'
#' @param dir base directory to look for shiny applications
#'
#' @describeIn app-folders App folders that are to be manually tested.
#' @export
apps_manual <- function(dir) {
  Filter(x = shiny_app_dirs(dir), function(x) is_manual_app(x))
}

#' @describeIn app-folders App folders that contain a \verb{shinytest.R} file
#' @export
apps_shinytest <- function(dir) {
  apps_runtests(dir, filter = "shinytest")
}

#' @describeIn app-folders App folders that contain the text \code{shinyjster} in a Shiny R file
#' @export
apps_shinyjster <- function(dir) {
  apps_runtests(dir, filter = "shinyjster")
}

#' @describeIn app-folders App folders that contain a \verb{testthat.R} file
#' @export
apps_testthat <- function(dir) {
  apps_runtests(dir, "testthat")
}

#' @describeIn app-folders App folders that contain a \verb{./tests} directory
#' @param filter regex to run on file name in the \verb{./tests} directory
#' @export
apps_runtests <- function(dir, filter = NULL) {
  files <- list.files(
    path = dir,
    pattern = "^tests$",
    include.dirs = TRUE,
    recursive = TRUE
  )

  if (!is.null(filter)) {
    files <- Filter(x = files, function(app_folder) {
      any(
        grepl(
          filter,
          list.files(
            # app_folder already contains `tests` folder
            file.path(dir, app_folder),
            pattern = "\\.r$",
            ignore.case = TRUE
          )
        )
      )
    })
  }
  dirname(files)
}


#' @describeIn app-folders App folders that contain a any Shiny app file
#' @export
apps_deploy <- function(dir) {
  shiny_app_dirs(dir)
}



shiny_app_dirs <- function(dir) {
  app_folders <- list.dirs(dir, full.names = TRUE, recursive = FALSE)
  Filter(x = app_folders, function(app_folder) {
    return(
      has_shiny_app_files(app_folder) ||
      has_rmarkdown_app_files(app_folder)
    )
  })
}
shiny_app_files <- function(app_folder) {
  dir(app_folder, pattern = "^(app|ui|server)\\.(r|R)$", full.names = TRUE)
}
has_shiny_app_files <- function(app_folder) {
  length(shiny_app_files(app_folder) > 0)
}
rmarkdown_app_files <- function(app_folder) {
  dir(app_folder, pattern = "^index\\.(Rmd|rmd)$", full.names = TRUE)
}
has_rmarkdown_app_files <- function(app_folder) {
  length(rmarkdown_app_files(app_folder) > 0)
}

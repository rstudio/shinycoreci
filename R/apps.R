
#' Get names of Shiny apps to be tested
#'
#' All \code{apps_*} methods inspect each application to determine if if testing is possible.
#'
#' @param dir base directory to look for shiny applications
#'
#' @describeIn app-folders App folders that are to be manually tested. See [is_manual_app()].
#' @export
apps_manual <- function(dir) {
  Filter(x = shiny_app_dirs(dir), function(x) is_manual_app(x))
}

#' @describeIn app-folders App folders that contain a \verb{shinytest.R} file
#' @param suffix if a suffix string is provided, it will be appended to the shinytest flag used to search for apps that should not be tested with shinytest. If a null value or non character string is provided, all shinytest flags will be found.
#' @export
apps_shinytest <- function(dir, suffix = NULL) {
  files <- list.files(
    path = dir,
    pattern = "shinytest.R$",
    recursive = TRUE,
    full.names = TRUE
  )
  flag <- append_flag(shinytest_app_info$flag, suffix)
  files <- Filter(x = files, function(file) {
    !any(grepl(flag, readLines(file)))
  })
  basename(dirname(dirname(files)))
}


#' @describeIn app-folders App folders that contain the text \code{shinyjster} in a Shiny R file
#' @param browser if a browser string is provided, it will be appended to the shinyjster flag used to search for apps that should not be tested with shinyjster. If a null value or non character string is provided, all shinyjster flags will be found.
#' @export
apps_shinyjster <- function(dir, browser = NULL) {
  jster_flag <- append_flag(jster_app_info$flag, browser)
  app_folders <- shiny_app_dirs(dir)
  calls_shinyjster <- vapply(app_folders, function(folder) {
    if (file.exists(file.path(folder, "_shinyjster.R"))) {
      return(TRUE)
    }

    app_or_ui_file <- c(shiny_app_files(folder), rmarkdown_app_files(folder))[1]

    lines <- readLines(app_or_ui_file)
    (
      # if shinyjster appears in the file... success!
      any(grepl("shinyjster", lines)) &&
      # as long as the flag is not found
      !any(grepl(jster_flag, lines))
    )

  }, logical(1))

  app_folders <- app_folders[calls_shinyjster]
  # Strip off leading dir, which was passed to this function.
  app_folders <- substring(app_folders, nchar(dir) + 2, 10000)
  app_folders
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


#' @describeIn app-folders App folders that contain a any Shiny app file
#' @export
apps_deploy <- function(dir) {
  app_folders <- shiny_app_dirs(dir)
  Filter(x = app_folders, function(app_folder) {
    return(
      has_shiny_app_files(app_folder) ||
      has_rmarkdown_app_files(app_folder)
    )
  })
}



shiny_app_dirs <- function(dir) {
  list.dirs(dir, full.names = TRUE, recursive = FALSE)
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

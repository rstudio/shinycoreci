manual_app_info <- list(
  string = "### Keep this line to manually test this shiny application. Do not edit this line; shinycoreci::::is_manual_app",
  flag = "shinycoreci::::is_manual_app"
)

#' Flag an app to be manually tested
#'
#' All \code{apps_*} methods inspect each application to determine if if testing is possible.
#'
#' @param app_dir Shiny application directory containing an app.R, ui.R, server.R, or index.Rmd
#' @rdname use_manual_app
#' @export
is_manual_app <- function(app_dir) {
    app_or_ui_files <- c(shiny_app_files(app_dir), rmarkdown_app_files(app_dir))

    flag <- manual_app_info$flag
    for (app_file in app_or_ui_files) {
      if (
        any(grepl(
          # if the flag appears in the file... success!
          flag,
          readLines(app_file, n = 20)
        ))
      ) {
        return(TRUE)
      }
    }
    FALSE
}
#' @rdname use_manual_app
#' @export
use_manual_app <- function(app_dir) {
  # find the first file
  app_or_ui_files <- c(shiny_app_files(app_dir), rmarkdown_app_files(app_dir))
  if (length(app_or_ui_files) == 0) {
    stop("No shiny files found in '", app_dir, "' to add manual flag")
  }
  app_or_ui_file <- normalizePath(app_or_ui_files[1])
  # read the lines
  file_lines <- readLines(app_or_ui_file)

  if (any(grepl(manual_app_info$flag, file_lines))) {
    message(app_dir, " is already a manual app. Returning")
    return(invisible())
  }

  # save the lines
  cat(
    file = app_or_ui_file,
    paste0(c(
      manual_app_info$string, # flag
      "", "", # white space
      file_lines, # content
      "" # EOF
    ), collapse = "\n")
  )
}



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

    app_or_ui_file <- c(shiny_app_files(folder), rmarkdown_app_files(folder))[1]

    # if shinyjster appears in the file... success!
    any(grepl(
      "shinyjster",
      readLines(app_or_ui_file)
    ))
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

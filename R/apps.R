
# #' Get names of Shiny apps to be tested
# #'
# #' All \code{apps_*} methods inspect each application to determine if if testing is possible.
# #'
# #' @param dir base directory to look for shiny applications
# #'
# #' @describeIn app-folders App folders that are to be manually tested.
# #' @export
# apps_manual <- function(dir) {
#   stop("DEPRECATED")
#   basename(Filter(x = file.path(dir, shiny_app_dirs(dir)), function(x) is_manual_app(x)))
# }

# #' @describeIn app-folders App folders that contain a \verb{shinytest.R} file
# #' @export
# apps_shinytest <- function(dir) {
#   stop("DEPRECATED")
#   apps_runtests(dir, filter = "shinytest")
# }

# #' @describeIn app-folders App folders that contain the text \code{shinyjster} in a Shiny R file
# #' @export
# apps_shinyjster <- function(dir) {
#   stop("DEPRECATED")
#   apps_runtests(dir, filter = "shinyjster")
# }

# #' @describeIn app-folders App folders that contain a \verb{testthat.R} file
# #' @export
# apps_testthat <- function(dir) {
#   stop("DEPRECATED")
#   apps_runtests(dir, "testthat")
# }

# #' @describeIn app-folders App folders that contain a \verb{./tests} directory
# #' @param filter regex to run on file name in the \verb{./tests} directory
# #' @export
# apps_runtests <- function(dir, filter = NULL) {
#   stop("DEPRECATED")
#   files <- list.files(
#     path = dir,
#     pattern = "^tests$",
#     include.dirs = TRUE,
#     recursive = TRUE
#   )

#   if (!is.null(filter)) {
#     files <- Filter(x = files, function(app_folder) {
#       any(
#         grepl(
#           filter,
#           list.files(
#             # app_folder already contains `tests` folder
#             file.path(dir, app_folder),
#             pattern = "\\.r$",
#             ignore.case = TRUE
#           )
#         )
#       )
#     })
#   }
#   dirname(files)
# }


# #' @describeIn app-folders App folders that contain a any Shiny app file
# #' @export
# apps_deploy <- function(dir) {
#   stop("DEPRECATED")
#   shiny_app_dirs(dir)
# }



# shiny_app_dirs <- function(dir) {
#   app_folders <- list.dirs(dir, full.names = TRUE, recursive = FALSE)
#   basename(Filter(x = app_folders, function(app_folder) {
#     return(
#       has_shiny_app_files(app_folder) ||
#       has_rmarkdown_app_files(app_folder)
#     )
#   }))
# }



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
has_shinyish_files <- function(app_folder) {
  has_shiny_app_files(app_folder) || has_rmarkdown_app_files(app_folder)
}
has_tests_folder <- function(app_folder) {
  "tests" %in% dir(app_folder)
}



# Flag must be at the end of the line
manual_app_info <- list(
  string = "### Keep this line to manually test this shiny application. Do not edit this line; shinycoreci::::is_manual_app",
  flag = "shinycoreci::::is_manual_app"
)

is_manual_app <- function(app_dir) {
  app_or_ui_files <- c(shiny_app_files(app_dir), rmarkdown_app_files(app_dir))

  flag <- manual_app_info$flag
  for (app_file in app_or_ui_files) {
    if (
      any(grepl(
        # if the flag appears in the file... success!
        flag,
        readLines(app_file, n = 100)
      ))
    ) {
      return(TRUE)
    }
  }
  FALSE
}





apps_folder <- system.file(package = "shinycoreci", "apps")
app_names <- dir(apps_folder)
app_names <- grep("^\\d\\d\\d-", app_names, value = TRUE)
app_nums <- as.numeric(vapply(strsplit(app_names, "-"), `[[`, character(1), 1))
app_name_map <- setNames(as.list(app_names), app_names)
app_num_map <- setNames(as.list(app_names), as.character(app_nums))

app_paths <- file.path(apps_folder, app_names)
app_path_map <- setNames(as.list(app_paths), app_names)

apps_manual <- basename(Filter(x = app_paths, is_manual_app))
apps_shiny  <- basename(Filter(x = app_paths, has_shinyish_files))
apps_tests  <- basename(Filter(x = app_paths, has_tests_folder))

# Flag must be at the end of the line
manual_app_info <- list(
  string = "### Keep this line to manually test this shiny application. Do not edit this line; shinycoreci::::is_manual_app",
  flag = "shinycoreci::::is_manual_app"
)
jster_app_info <- list(
  string = "### Keep this line to NOT test this shiny application with shinycoreci::test_shinyjster. Do not edit this line; shinycoreci::::not_jster_app",
  # may contain an extra "_BROWSER" appended
  flag = "shinycoreci::::not_jster_app"
)
shinytest_app_info <- list(
  string = "### Keep this line to NOT test this shiny application with shinycoreci::test_shinytest. Do not edit this line; shinycoreci::::not_shinytest_app",
  # may contain an extra "_PLATFORM" appended
  flag = "shinycoreci::::not_shinytest_app"
)

append_flag <- function(flag, suffix = NULL) {
  if (
    (!is.null(suffix)) &&
    is.character(suffix) &&
    nchar(suffix) > 0
  ) {
    paste0(
      "(",
      # global, no-suffix flag
      flag,
      "|",
      # suffix flag
      paste0(flag, "_", tolower(suffix)),
      ")$"
    )
  } else {
    paste0(flag, "$")
  }
}

#' Flag an app to be manually tested
#'
#' All \code{apps_*} methods inspect each application to determine if if testing is possible.
#'
#' @param app_dir Shiny application directory containing an app.R, ui.R, server.R, or index.Rmd
#' @rdname use_manual_app
#' @export
is_manual_app <- function(app_dir) {
    app_or_ui_files <- c(shiny_app_files(app_dir), rmarkdown_app_files(app_dir))

    flag <- append_flag(manual_app_info$flag)
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

  content <-
    if (grepl("index\\.Rmd", basename(app_or_ui_file))) {
      first_yaml_header_line <- min(which(grepl("---", file_lines)))
      if (length(first_yaml_header_line) == 0) {
        stop("Could not find yaml header line in ", app_or_ui_file)
      }

      # insert the line just inside the yaml header
      # (will be treated as a yaml comment)
      file_lines <- append(file_lines, manual_app_info$string, after = first_yaml_header_line)
      file_lines

    } else {
      paste0(c(
        manual_app_info$string, # flag
        "", # white space
        file_lines
      ))
    }

  # save the lines
  cat(
    file = app_or_ui_file,
    paste0(c(
      content, # content
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

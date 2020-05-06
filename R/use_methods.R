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

#' Flag an app to be manually tested
#'
#' All \code{apps_*} methods inspect each application to determine if if testing is possible.
#'
#' @param app_dir Shiny application directory containing an app.R, ui.R, server.R, or index.Rmd
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



#' Create Shinyjster test file
#'
#' This creates a testing file to be used with [test_runtests()].  It will create a file for each browser.
#'
#' @param app_dir Location of shiny application to test
#' @seealso [test_shinyjster()]
#' @export
use_tests_shinyjster <- function(app_dir) {

  for (browser_name in c("chrome", "firefox", "edge", "ie")) {
    save_use_file(
      file.path(app_dir, "tests", paste0("shinyjster-", browser_name, ".R")),
      paste0(
        "shinycoreci::test_shinyjster_app(\"", browser_name, "\")"
      )
    )
  }

  invisible(app_dir)
}

#' Create Shinyjster test file
#'
#' @param app_dir Location of shiny application to test
#' @seealso [test_shinytest()]
#' @export
use_tests_shinytest <- function(app_dir) {

  save_use_file(
    file.path(app_dir, "tests", "shinytest.R"),
    "shinycoreci::test_shinytest_app()"
  )

  save_use_file(
    file.path(app_dir, "tests", "shinytest", "mytest.R"),
    paste0(
      'app <- ShinyDriver$new("../../", seed = 100, shinyOptions = list(display.mode = "normal"))',
      'app$snapshotInit("mytest")',
      '',
      'app$snapshot()',
      collapse = "\n"
    )
  )

  invisible(app_dir)
}


#' Create an app testthat test file
#'
#' @param app_dir Location of shiny application to test
#' @seealso [test_testthat()]
#' @export
use_tests_testthat <- function(app_dir) {

  save_use_file(
    file.path(app_dir, "tests", "testthat.R"),
    "shinycoreci::test_testthat_app()"
  )

  save_use_file(
    file.path(app_dir, "tests", "testthat", "tests.R"),
    paste0(
      'context("server")',
      '',
      'test_that("server works", {',
      '  testServer(expr = {',
      '    ',
      '  })',
      '})',
      collapse = "\n"
    )
  )

  invisible(app_dir)
}

# Helper function to create the enclosing directory and save the file if it doesn't already exist
save_use_file <- function(file_path, content) {
  file_dir <- dirname(file_path)
  if (!dir.exists(file_dir)) {
    message("Creating ", file_dir)
    dir.create(file_dir)
  }

  if (file.exists(file_path)) {
    message(file_path, " already exists")
  } else {
    message("Creating ", file_path)
    cat(
      content, "\n",
      file = file_path,
      sep = ""
    )
  }
}

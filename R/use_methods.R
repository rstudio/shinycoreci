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
#' @seealso [test_jster()]
#' @export
use_tests_shinyjster <- function(app_dir) {

  test_path <- file.path(app_dir, "tests")
  if (!dir.exists(test_path)) {
    message("Creating ", test_path)
    dir.create(test_path)
  }
  windows_browser_names <- c("edge", "ie")
  browser_names <- c("chrome", "firefox", windows_browser_names)
  for (browser_name in browser_names) {
    shinyjster_test_file <- file.path(test_path, paste0("shinyjster-", browser_name, ".R"))

    if (file.exists(shinyjster_test_file)) {
      message(shinyjster_test_file, " already exists")
      next
    }

    message("Creating ", shinyjster_test_file)
    content <- paste0(
      "shinyjster::test_jster(browser = shinyjster::selenium_", browser_name, "(), type = \"lapply\")"
    )

    if (browser_name %in% windows_browser_names) {
      content <- paste0(
        "if (shinycoreci::platform() == \"win\") {\n",
        "  ", content, "\n",
        "}"
      )
    }
    cat(content, "\n", file = shinyjster_test_file, sep = "")
  }

  invisible(app_dir)
}

#' @export
use_tests_shinytest <- function(app_dir) {
  test_path <- file.path(app_dir, "tests")
  if (!dir.exists(test_path)) {
    message("Creating ", test_path)
    dir.create(test_path)
  }
  shinytest_test_file <- file.path(test_path, paste0("shinytest.R"))


  if (file.exists(shinytest_test_file)) {
    message(shinytest_test_file, " already exists")
  } else {
    message("Creating ", shinytest_test_file)
    content <- paste0(
      "library(shinytest)",
      "shinytest::expect_pass(",
      "  shinytest::testApp(",
      "    \"../\",",
      "    suffix = shinycoreci::platform()",
      "  )",
      ")",
      collapse = "\n"
    )
    cat(content, "\n", file = shinytest_test_file, sep = "")
  }

  shinytest_folder <- file.path(test_path, "shinytest")
  if (!dir.exists(shinytest_folder)) {
    message("Creating ", shinytest_folder)
    dir.create(shinytest_folder, recursive = TRUE)
  }

  shinytest_mytest_file <- file.path(shinytest_folder, "mytest.R")
  if (file.exists(shinytest_mytest_file)) {
    message(shinytest_mytest_file, " already exists")
  } else {
    message("Creating ", shinytest_mytest_file)

    content <- paste0(
      'app <- ShinyDriver$new("../../", seed = 100, shinyOptions = list(display.mode = "normal"))',
      'app$snapshotInit("mytest")',
      '',
      'app$snapshot()',
      collapse = "\n"
    )
    cat(content, "\n", file = shinytest_mytest_file, sep = "")
  }

  invisible(app_dir)
}

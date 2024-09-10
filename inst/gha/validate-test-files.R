# Execute with `source("inst/gha/validate-test-files.R")`

errors_found <- list()

app_folders <- basename(list.dirs("inst/apps", recursive = FALSE))
app_folder_nums <- sub("^(\\d\\d\\d)-.*$", "\\1", app_folders)
# Can not call `setdiff()`. This internally calls `unique()`
app_folder_nums <- app_folder_nums[!(app_folder_nums %in% c("000"))]
if (any(duplicated(app_folder_nums))) {
  stop("Duplicate app numbers found: ", paste0(app_folder_nums[duplicated(app_folder_nums)], collapse = ", "))
}

for (app_path in list.dirs("inst/apps", recursive = FALSE)) {
  tryCatch({

    app_files <- dir(app_path, pattern = "\\.(R|Rmd)$", full.names = TRUE)
    tests_path <- file.path(app_path, "tests")
    if (dir.exists(tests_path)) {
      runners <- dir(tests_path, pattern = "R$")
      if (length(runners) > 1) {
        stop("More than 1 test runner found in ", app_path, ". Found: ", paste0(runners, collapse = ", "))
      }
      # Verify simple testthat.R
      testthat_path <- file.path(tests_path, "testthat.R")
      if (!file.exists(testthat_path)) {
        stop("Missing `testthat.R` for app: ", app_path)
      }
      testthat_lines <- readLines(testthat_path)
      if (length(testthat_lines) > 1) {
        stop("Non-basic testthat script found for ", testthat_path, ". Found:\n", paste0(testthat_lines, "\n"))
      }
      if (testthat_lines != "shinytest2::test_app()") {
        stop("Non-shinytest2 testthat script found for ", testthat_path, ". Found:\n", paste0(testthat_lines, "\n"))
      }

      # Verify shinyjster content
      shinyjster_file <- file.path(tests_path, "testthat", "test-shinyjster.R")
      if (file.exists(shinyjster_file)) {
        for (jster_txt in c("shinyjster_server(", "shinyjster_js(")) {
          found <- FALSE
          for (app_file in app_files) {
            if (any(grepl(jster_txt, readLines(app_file), fixed = TRUE))) {
              found <- TRUE
              break
            }
          }
          if (!found) {
            stop(app_path, " did not contain ", jster_txt, " but contains a `./tests/testthat/test-shinyjster.R")
          }
        }
      }

    } else {
      # Test for manual app
      found <- FALSE
      for (app_file in app_files) {
        if (any(grepl("shinycoreci::::is_manual_app", readLines(app_file), fixed = TRUE))) {
          found <- TRUE
          break
        }
      }
      if (!found) {
        stop(
          "No `./", app_path, "/tests` folder found for non-manual app.\n",
          "Either add tests with `shinytest2::use_shinytest2('", app_path, "')`\n",
          "Or set to manual by calling `shinycoreci::use_manual_app('", app_path, "')`"
        )
      }
    }

    # # Make sure shinycoreci is not used within an app
    # for (file in dir(app_path, recursive = TRUE, full.names = TRUE, pattern = "\\.(R|Rmd)$")) {
    #   # Ignore first 000 apps
    #   if (grepl("^inst/apps/000-", file)) next

    #   file_lines <- readLines(file)
    #   if (any(grepl("shinycoreci)", file_lines, fixed = TRUE))) {
    #     stop("File `", file, "` contains library() or require() call to {shinycoreci}. Remove usage of {shinycoreci}.")
    #   }
    #   file_lines <- gsub("shinycoreci::::", "shinycoreci____", file_lines)
    #   if (any(grepl("shinycoreci::", file_lines, fixed = TRUE))) {
    #     stop("File `", file, "` contains usage of {shinycoreci}. Replace this code.")
    #   }
    # }
  }, error = function(e) {
    errors_found[[length(errors_found) + 1]] <<- e
  })
}

if (length(errors_found) > 0) {
  for (e in errors_found) {
    message("\n", e)
  }
  stop("Errors found when validating apps")
}

# warns <- warnings()
# if (length(warns) > 0) {
#   warn_txt <- Map(names(warns), warns, f = function(msg, expr) { paste0(msg, " : ", as.character(as.expression(expr)), "\n") })
#   stop("Warnings found when validating apps:\n", paste0(warn_txt, collapse = ""))
# }

message("No errors found when validating apps")

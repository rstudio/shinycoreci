#' Test apps using `shiny::runTests()`
#'
#' @param dir base folder to look for applications
#' @param apps applications within \verb{dir} to run
#' @param filter filter to use on test file within application
#' @param assert logical value which will determine if [assert_runtests()] will be called on the result
#' @param timeout Length of time allowed for an application's full test suit can run before determining it is a failure
#' @param retries number of attempts to retry before declaring the test a failure
#' @describeIn runtests Generic method to call all testing files
#' @export
test_runtests <- function(
  dir = "apps",
  apps = apps_runtests(dir, filter = filter),
  filter = NULL,
  assert = TRUE,
  timeout = as.difftime(10, units = "mins"),
  retries = 2,
) {
  req_core_pkgs()

  force(apps)
  retries <- as.numeric(retries)

  # Record platform info and package versions
  write_sysinfo(file.path(dir, paste0("sysinfo-", platform_rversion(), ".txt")))

  run_test <- function(app_dir_val, filter_val) {
    message("Testing ", app_dir_val)
    tryCatch(
      {
        callr::r(
          function(app_dir_val_, filter_val_) {
            shiny::runTests(
              appDir = app_dir_val_,
              filter = filter_val_,
              assert = FALSE,
              envir = new.env(parent = globalenv())
            )
          },
          list(
            app_dir_val_ = app_dir_val,
            filter_val_ = filter_val
          ),
          show = TRUE,
          timeout = timeout
        )
      },
      error = function(e) {
        # don't know which test failed, so must provide a failure to all tests

        runners <- list.files(file.path(app_dir_val, "tests"), pattern = "\\.r$", ignore.case = TRUE, full.names = TRUE)
        if (!is.null(filter_val)) {
          runners <- runners[grepl(filter_val, runners)]
        }
        error_ret <- as.data.frame(tibble::tibble(
          file = runners,
          pass = FALSE,
          result = replicate(length(runners), list(e))
        ))
        class(error_ret) <- c("shiny_runtests", class(error_ret))
        error_ret
      }
    )
  }

  ret_list <- lapply(
    file.path(dir, apps),
    function(app_path) {
      run_test(app_path, filter)
    }
  )
  ret <- do.call(rbind, ret_list)

  # if any failures exist...
  while (any(!ret$pass) && retries > 0) {

    failure_positions <- which(!ret$pass)
    # for each failing file position...
    for (failure_position in failure_positions) {
      # get the failure test file
      failure_file <- ret$file[failure_position]
      # test that single file
      ans <- run_test(
        dirname(dirname(failure_file)),
        # use the full name for a single match only
        basename(failure_file)
      )
      # store result
      if (failure_file != ans$file[1]) {
        utils::str(list(
          failed_file = failure_file,
          new_file = ans$file[1]
        ))
        stop("when retrying, the file names do not match")
      }
      ret$pass[failure_position] <- ans$pass[1]
      ret$result[failure_position] <- ans$result[1]
    }

    # decrement retry count
    retries <- retries - 1
  }

  # Remove NULL result test files
  is_empty_result <- vapply(ret$result, is.null, logical(1))
  ret <- ret[!is_empty_result, ]

  if (isTRUE(assert)) {
    assert_runtests(ret)
  }

  ret
}



#' @describeIn runtests Only execute shinytest.R test files
#' @export
test_shinytest <- function(
  dir = "apps",
  apps = apps_shinytest(dir),
  assert = TRUE,
  retries = 3
) {
  test_runtests(
    dir = dir,
    apps = apps,
    filter = "shinytest",
    assert = assert,
    retries = retries
  )
}

#' @describeIn runtests Only execute shinyjster.R test files
#' @export
test_shinyjster <- function(
  dir = "apps",
  apps = apps_shinyjster(dir),
  assert = TRUE,
  retries = 3
) {
  test_runtests(
    dir = dir,
    apps = apps,
    filter = "shinyjster",
    assert = assert,
    retries = retries
  )
}

#' @describeIn runtests Only execute testtat.R test files
#' @export
test_testthat <- function(
  dir = "apps",
  apps = apps_testthat(dir),
  assert = TRUE,
  retries = 3
) {
  test_runtests(
    dir = dir,
    apps = apps,
    filter = "testthat",
    assert = assert,
    retries = retries
  )
}



#' Assert [test_runtests()] output
#'
#' Method called when [test_runtests()] is called with `assert = TRUE`.
#'
#' @param test_runtests_output value received from [test_runtests()]
#' @export
assert_runtests <- function(test_runtests_output) {
  if (!inherits(test_runtests_output, "shiny_runtests")) {
    stop("`test_runtests_output` does not have class `'shiny_runtests'`")
  }
  ret <- test_runtests_output

  if (all(ret$pass)) {
    message("All app tests passed!")
    return()
  }


  failure_ret <- ret[!ret$pass, ]
  failed_files <- failure_ret$file

  failed_test_folders <- dirname(failed_files)
  failed_app_folders <- dirname(failed_test_folders)
  pretty_fail_paths <- file.path(basename(failed_app_folders), basename(failed_test_folders), basename(failed_files))

  message("App test failures:")
  mapply(
    pretty_fail_paths,
    failure_ret$result,
    FUN = function(pretty_fail_path, result) {

      cat("\n")
      message("* ", pretty_fail_path, ": ")
      print(result)
      cat("\n")
    }
  )

  stop(
    "Failures detected in\n",
    paste0("* ", pretty_fail_paths, collapse = "\n")
  )

}

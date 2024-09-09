ci_status <- list(
  default = "unknown",
  pass = "pass",
  fail = "fail",
  no_install = "can_not_install",
  did_not_return_result = "did_not_return_result"
)

#' Test apps using `shiny::runTests()` using local libpath
#'
#' @param apps applications within \verb{dir} to run
#' @param assert logical value which will determine if [assert_test_output()] will be called on the result
#' @param timeout Length of time allowed for an application's full test suit can run before determining it is a failure
#' @param retries number of attempts to retry before declaring the test a failure
#' @param repo_dir Location of local shinycoreci repo
#' @param ... ignored
#' @inheritParams resolve_libpath
#' @export
test_in_local <- function(
    apps = apps_with_tests(repo_dir),
    ...,
    assert = TRUE,
    timeout = 10 * 60,
    retries = 2,
    repo_dir = rprojroot::find_package_root_file(),
    local_pkgs = FALSE) {
  retries <- as.numeric(retries)
  repo_dir <- normalizePath(repo_dir, mustWork = TRUE)

  should_install <- !isTRUE(local_pkgs)
  libpath <- resolve_libpath(local_pkgs = local_pkgs)

  stopifnot(length(apps_with_tests(repo_dir)) > 0)
  apps <- resolve_app_name(apps, known_apps = apps_with_tests(repo_dir))

  withr::defer({
    # Record platform info and package versions (after everything has been installed)
    write_sysinfo(
      file.path(repo_apps_path(repo_dir), paste0("sysinfo-", platform_rversion(), ".txt")),
      libpath = libpath
    )
  })

  test_dt <- tibble::tibble(
    app_name = apps,
    status = ci_status$default,
    result = replicate(length(apps), list()),
    log = replicate(length(apps), "(not run yet)")
  )

  run_test <- function(app_name, show_output = TRUE) {
    if (should_install) {
      install_result <- try({
        install_missing_app_deps(app_name, libpath = libpath, verbose = show_output)
      })
      # Check for installation results
      if (inherits(install_result, "try-error")) {
        tmpfile <- tempfile()
        app_deps <- apps_deps_map[[app_name]]
        cat(
          file = tmpfile,
          "Failed to install:\n", paste0("* ", app_deps, "\n"),
          "\nError:\n", as.character(install_result), "\n"
        )
        return(list(
          status = ci_status$no_install,
          result = as.character(install_result),
          log_file = tmpfile
        ))
      }
    }

    log_file <- tempfile("coreci-log-", fileext = ".log")

    tryCatch(
      {
        test_result <- callr::r(
          function(app_path_) {
            withr::with_envvar(
              list(NOT_CRAN = "true"),
              {
                message("\n###\nRunning tests for app: ", basename(app_path_), "\n")
                on.exit(
                  {
                    message("\nStopping tests for app: ", basename(app_path_), "\n###")
                  },
                  add = TRUE
                )

                shiny::runTests(
                  appDir = app_path_,
                  assert = FALSE
                )
              }
            )
          },
          list(
            app_path_ = repo_app_path(app_name, repo_dir = repo_dir)
          ),
          libpath = libpath,
          timeout = timeout,
          stdout = log_file,
          stderr = "2>&1",
          show = show_output,
          supervise = TRUE
        )
        result <- test_result$result[[1]]
        status <-
          if (is.null(result)) {
            ci_status$did_not_return_result
          } else {
            if (isTRUE(test_result$pass[1])) {
              ci_status$pass
            } else {
              ci_status$fail
            }
          }
        list(
          status = status,
          result = result,
          log_file = log_file
        )
      },
      error = function(e) {
        # return a failed test
        list(
          status = ci_status$fail,
          result = e,
          log_file = log_file
        )
      }
    )
  }

  # (break statements at beginning and end of while loop)
  show_output <- TRUE # temp enable output for debugging
  while (TRUE) {
    # get all positions that should be tested
    to_test_positions <- which(test_dt$status %in% c(ci_status$fail, ci_status$default))
    if (length(to_test_positions) == 0) {
      # no failing or unknown tests remain; stop testing
      break
    }

    pb <- progress_bar(
      total = length(to_test_positions),
      format = "[:current/:total; :elapsed; :eta] :app\n",
      clear = FALSE,
      show_after = 0
    )
    # for each file position...
    for (to_test_position in to_test_positions) {
      # get the failure test file
      app_name <- test_dt$app_name[to_test_position]

      pb$tick(tokens = list(
        app = app_name
      ))

      # test that single file
      ## list(
      ##   status = VAL,
      ##   result = VAL
      ## )
      ans <- run_test(app_name, show_output = show_output)

      # store result
      log_content <-
        if (file.exists(ans$log_file)) {
          content <- paste0(readLines(ans$log_file), collapse = "\n")
          unlink(ans$log_file)
          content
        } else {
          "(no log file found)"
        }
      test_dt$status[to_test_position] <- ans$status
      test_dt$result[to_test_position] <- list(ans$result)
      test_dt$log[to_test_position] <- log_content

      # ans$status should _always_ be of length 1 (otherwise assignment above would fail)
      if (ans$status == ci_status$default) {
        utils::str(app_name)
        utils::str(ans)
        stop("An status of ", ci_status$default, " should never be stored")
      }
    }

    if (retries <= 0) {
      # can not retry anymore; stop testing
      break
    }
    message("\n\nRetrying failed tests... (Displaying test output from now on)")
    retries <- retries - 1
    show_output <- TRUE
  }

  class(test_dt) <- c("shinycoreci_test_output", class(test_dt))

  if (isTRUE(assert)) {
    assert_test_output(test_dt)
  }

  test_dt
}


#' Assert [test_in_local()] output
#'
#' Method called when [test_in_local()] is called with `assert = TRUE`.
#'
#' @param output value received from [test_in_local()]
#' @export
assert_test_output <- function(output) {
  if (!inherits(output, "shinycoreci_test_output")) {
    stop("`output` does not have class `'shinycoreci_test_output'`")
  }
  test_dt <- output

  concat_info <- function(title, statuses, include_result = TRUE) {
    sub_rows <- test_dt$status %in% statuses
    sub_test_dt <- test_dt[sub_rows, ]
    sub_app_name <- sub_test_dt$app_name

    content_ret <- mapply(
      sub_app_name,
      sub_test_dt$log,
      FUN = function(app_name, log) {
        result_str <- if (include_result) log else ""
        paste0("* ", app_name, result_str)
      }
    )

    paste0(
      title, "\n",
      paste0(
        content_ret,
        collapse = if (include_result) "\n\n" else "\n"
      ),
      "\n"
    )
  }

  has_shown <- FALSE
  display_message <- function(title, statuses, include_result) {
    if (any(test_dt$status %in% statuses)) {
      message(
        if (has_shown) "\n" else "",
        concat_info(paste0(title, ":"), statuses, include_result = include_result)
      )
      has_shown <<- TRUE
    }
  }
  # display_message("App test successes",                 ci_status$pass,                  include_result = FALSE)
  display_message("Apps which did not return a result", ci_status$did_not_return_result, include_result = FALSE)
  display_message("App test failures", ci_status$fail, include_result = TRUE)
  display_message("Apps which could NOT be tested", ci_status$no_install, include_result = TRUE)

  # Cover case of complete install failure for all apps
  if (!any(test_dt$status %in% c(ci_status$pass, ci_status$fail))) {
    stop("No test results found!")
  }

  if (any(test_dt$status %in% ci_status$fail)) {
    stop(
      concat_info("Failures detected in:", c(ci_status$fail), include_result = FALSE)
    )
  } else {
    message("All app tests passed!")
  }

  invisible(test_dt)
}

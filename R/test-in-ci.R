ci_status <- list(
  default = "unknown",
  pass = "pass",
  fail = "fail",
  no_install = "can_not_install",
  did_not_return_result = "did_not_return_result"
)

#' Test apps using `shiny::runTests()`
#'
#' @param apps applications within \verb{dir} to run
#' @param assert logical value which will determine if [assert_ci_output()] will be called on the result
#' @param timeout Length of time allowed for an application's full test suit can run before determining it is a failure
#' @param retries number of attempts to retry before declaring the test a failure
#' @describeIn runtests Generic method to call all testing files
#' @export
test_in_ci <- function(
  apps = apps_tests,
  assert = TRUE,
  timeout = 10 * 60,
  retries = 2,
  repo_dir = "."
) {
  retries <- as.numeric(retries)
  apps <- resolve_app_name(apps)
  repo_dir <- normalizePath(repo_dir, mustWork = TRUE)

  libpath <- install_shinyverse_ci()

  # # Do not include apps here, only make sure shinyverse is intact
  # # the only thing to make sure remains is the CRAN packages for each app
  # validate_exact_deps(dir = dir, apps = c(), update_pkgs = update_pkgs)

  # Record platform info and package versions
  write_sysinfo(file.path(repo_dir, "inst/apps", paste0("sysinfo-", platform_rversion(), ".txt")))

  test_dt <- tibble::tibble(
    app_name = apps,
    status = ci_status$default,
    result = replicate(length(apps), list())
  )

  run_test <- function(app_name) {

    tryCatch(
      {
        test_result <- callr::r(
          function(app_path_) {
            withr::with_envvar(
              list(NOT_CRAN = "true"),
              {
                shiny::runTests(
                  appDir = app_path_,
                  assert = FALSE
                )
              }
            )
          },
          list(
            app_path_ = app_path(app_name)
          ),
          libpath = libpath,
          timeout = timeout,
          show = TRUE
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
          result = result
        )
      },
      error = function(e) {
        # return a failed test
        list(
          status = ci_status$fail,
          result = e
        )
      }
    )
  }

  # (break statements at beginning and end of while loop)
  while (TRUE) {

    # get all positions that should be tested
    to_test_positions <- which(test_dt$status %in% c(ci_status$fail, ci_status$default))
    if (length(to_test_positions) == 0) {
      # no failing or unknown tests remain; stop testing
      break
    }

    pb <- progress_bar(
      total = length(to_test_positions),
      format = "[:current/:total;:elapsed;:eta] :app\n"
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
      ans <- run_test(app_name)

      # store result
      test_dt$status[to_test_position] <- ans$status
      test_dt$result[to_test_position] <- list(ans$result)
      # ans$status should _always_ be of length 1 (otherwise assignment above would fail)
      if (ans$status == ci_status$default) {
        utils::str(to_test_path)
        utils::str(ans)
        stop("An status of ", ci_status$default, " should never be stored")
      }
    }

    if (retries <= 0) {
      # can not retry anymore; stop testing
      break
    }
    retries <- retries - 1
  }

  class(test_dt) <- c("shinycoreci_ci_output", class(test_dt))

  if (isTRUE(assert)) {
    assert_ci_output(test_dt)
  }

  test_dt
}


#' Assert [test_in_ci()] output
#'
#' Method called when [test_in_ci()] is called with `assert = TRUE`.
#'
#' @param ci_output value received from [test_in_ci()]
#' @export
assert_ci_output <- function(ci_output) {
  if (!inherits(ci_output, "shinycoreci_ci_output")) {
    stop("`ci_output` does not have class `'shinycoreci_ci_output'`")
  }
  test_dt <- ci_output

  concat_info <- function(title, statuses, include_result = TRUE) {

    sub_rows <- test_dt$status %in% statuses
    sub_test_dt <- test_dt[sub_rows, ]
    sub_app_name <- sub_test_dt$app_name

    content_ret <- mapply(
      sub_app_name,
      sub_test_dt$result,
      FUN = function(app_name, result) {

        result_str <-
          if (include_result) {
            # TODO-barret; display rich results here
            paste0(
              "\n",
              paste0(
                utils::capture.output({
                  print(result)
                }),
                collapse = "\n"
              )
            )
          } else {
            ""
          }

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
  display_message("App test failures",                  ci_status$fail,                  include_result = TRUE)
  display_message("Apps which could NOT be tested",     ci_status$no_install,            include_result = TRUE)

  if (any(test_dt$status %in% ci_status$fail)) {
    stop(
      concat_info("Failures detected in:", c(ci_status$fail), include_result = FALSE)
    )
  } else {
    message("All app tests passed!")
  }

  invisible(test_dt)
}

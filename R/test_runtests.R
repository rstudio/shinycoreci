test_runtests_status <- list(
  default = "unknown",
  pass = "pass",
  fail = "fail",
  no_install = "can_not_install",
  did_not_return_result = "did_not_return_result"
)

#' Test apps using `shiny::runTests()`
#'
#' @param dir base folder to look for applications
#' @param apps applications within \verb{dir} to run
#' @param filter filter to use on test file within application
#' @param assert logical value which will determine if [assert_runtests()] will be called on the result
#' @param timeout Length of time allowed for an application's full test suit can run before determining it is a failure
#' @param retries number of attempts to retry before declaring the test a failure
#' @param update_pkgs Logical value which will try to install all required shiny packages used for testing
#' @param update_app_pkgs Logical value which will try to install all required app packages used for testing
#' @describeIn runtests Generic method to call all testing files
#' @export
test_runtests <- function(
  dir = "apps",
  apps = apps_runtests(dir, filter = filter),
  filter = NULL,
  assert = TRUE,
  timeout = as.difftime(10, units = "mins"),
  retries = 2,
  update_pkgs = TRUE,
  update_app_pkgs = TRUE
) {
  force(apps)
  retries <- as.numeric(retries)

  # do not include apps here, only make sure shinyverse is intact
  # the only thing to make sure remains is the CRAN packages for each app
  validate_exact_deps(dir = dir, apps = c(), update_pkgs = update_pkgs)

  # Record platform info and package versions
  write_sysinfo(file.path(dir, paste0("sysinfo-", platform_rversion(), ".txt")))



  # gather all test files
  test_files <- list.files(
    path = file.path(dir, apps, "tests"),
    pattern = "\\.[Rr]$",
    include.dirs = FALSE,
    full.names = TRUE
  )
  # if there is a filter, subset the test files
  if (!is.null(filter)) {
    test_files <- test_files[grepl(filter, basename(test_files))]
  }

  test_dt <- tibble::tibble(
    test_path = test_files,
    # test_file = basename(test_files),
    # app_name = basename(dirname(dirname(test_files))),
    status = test_runtests_status$default,
    result = replicate(length(test_files), list())
  )

  run_test <- function(test_path) {
    app_path <- dirname(dirname(test_path))

    if (isTRUE(update_app_pkgs)) {
      # (currently) does NOT handle `Remotes:` in the DESCRIPTION file
      is_available <- install_app_cran_deps(app_path)

      if (any(!is_available)) {
        failed_to_install <- names(is_available[!is_available])
        message("Apps: ", dput_arg(failed_to_install), " could not be installed. Skipping the testing of app: ", basename(app_path))
        return(list(
          status = test_runtests_status$no_install,
          result = failed_to_install
        ))
      }
    }

    tryCatch(
      {
        test_result <- callr::r(
          function(app_path_, filter_val_) {
            shiny::runTests(
              appDir = app_path_,
              filter = filter_val_,
              assert = FALSE,
              envir = new.env(parent = globalenv())
            )
          },
          list(
            app_path_ = app_path,
            # only test the particular test file
            filter_val_ = basename(test_path)
          ),
          show = TRUE,
          timeout = timeout
        )
        result <- test_result$result[[1]]
        status <-
          if (is.null(result)) {
            test_runtests_status$did_not_return_result
          } else {
            if (isTRUE(test_result$pass[1])) {
              test_runtests_status$pass
            } else {
              test_runtests_status$fail
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
          status = test_runtests_status$fail,
          result = e
        )
      }
    )
  }

  # (break statements at beginning and end of while loop)
  while (TRUE) {

    # get all positions that should be tested
    to_test_positions <- which(test_dt$status %in% c(test_runtests_status$fail, test_runtests_status$default))
    if (length(to_test_positions) == 0) {
      # no failing or unknown tests remain; exit testing
      break
    }

    pb <- progress::progress_bar$new(
      total = length(to_test_positions),
      format = "[:current/:total;:elapsed;:eta] :app ~ :file\n",
      show_after = 0,
      clear = FALSE
    )


    # for each file position...
    for (to_test_position in to_test_positions) {

      # get the failure test file
      to_test_path <- test_dt$test_path[to_test_position]

      pb$tick(tokens = list(
        app = basename(dirname(dirname(to_test_path))),
        file = basename(to_test_path)
      ))

      # test that single file
      ## list(
      ##   status = VAL,
      ##   result = VAL
      ## )
      ans <- run_test(to_test_path)

      # store result
      test_dt$status[to_test_position] <- ans$status
      test_dt$result[to_test_position] <- list(ans$result)
      # ans$status should _always_ be of length 1 (otherwise assignment above would fail)
      if (ans$status == test_runtests_status$default) {
        utils::str(to_test_path)
        utils::str(ans)
        stop("An status of ", test_runtests_status$default, " should never be stored")
      }
    }

    if (retries <= 0) {
      # can not retry anymore; stop testing
      break
    }
    retries <- retries - 1
  }

  class(test_dt) <- c("shinycoreci_runtests", class(test_dt))

  if (isTRUE(assert)) {
    assert_runtests(test_dt)
  }

  test_dt
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
  if (!inherits(test_runtests_output, "shinycoreci_runtests")) {
    stop("`test_runtests_output` does not have class `'shinycoreci_runtests'`")
  }
  test_dt <- test_runtests_output

  concat_info <- function(title, statuses, include_result = TRUE) {

    sub_rows <- test_dt$status %in% statuses
    sub_test_dt <- test_dt[sub_rows, ]
    sub_paths <- sub_test_dt$test_path
    sub_app_name <- basename(dirname(dirname(sub_paths)))

    content_ret <- mapply(
      basename(sub_paths),
      sub_app_name,
      sub_test_dt$result,
      FUN = function(test_file, app_name, result) {

        result_str <-
          if (include_result) {
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

        paste0(
          "* ", app_name, " ~ ", test_file,
          result_str
        )
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
  # display_message("App test successes",                 test_runtests_status$pass,                  include_result = FALSE)
  display_message("App test failures",                  test_runtests_status$fail,                  include_result = TRUE)
  display_message("Apps which did not return a result", test_runtests_status$did_not_return_result, include_result = FALSE)
  display_message("Apps which could NOT be tested",     test_runtests_status$no_install,            include_result = TRUE)

  if (any(test_dt$status %in% test_runtests_status$fail)) {
    stop(
      concat_info("Failures detected in:", c(test_runtests_status$fail), include_result = FALSE)
    )
  } else {
    message("All app tests passed!")
  }

  invisible(test_dt)
}


cached_install_cran_pkg <- local({
  cache <- list()

  function(package, install_if_needed = TRUE) {
    if (!is.character(package) || length(package) != 1) {
      utils::str(package)
      stop("`package` must be a character of length 1")
    }

    # if this package has already been seen, return it's value
    cache_val <- cache[[package]]
    if (!is.null(cache_val)) {
      return(cache_val)
    }

    # at this point, this package has NOT been checked

    # Make sure it isn't a github package
    desc_file <- system.file("DESCRIPTION", package = package)
    # if it is currently installed...
    if (nzchar(desc_file)) {
      # if the remote type is "github", force install from CRAN
      desc_dcf <- as.data.frame(read.dcf(desc_file))
      if (identical(desc_dcf$RemoteType[1], "github")) {
        install_cran_packages_safely(package)
      }
    }

    # Make sure the package is up to date
    did_install <- install_binary_or_source(package)

    cache[[package]] <<- did_install

    did_install
  }
})


install_app_cran_deps <- function(app_path, update_app_pkgs = TRUE) {
  if (!isTRUE(update_app_pkgs)) {
    return(logical(0))
  }
  # gather github installed packages (all other packages should be CRAN packages)
  packages_to_not_install_from_cran <-
    unique(c(
      "shinycoreci",
      unlist(cached_remotes_order()$remotes_to_install),
      as.data.frame(utils::installed.packages(priority = "base"))$Package,
      "datasets"
    ))

  # (currently) does NOT handle `Remotes:` in the DESCRIPTION file
  app_packages <- unique(renv::dependencies(app_path, quiet = TRUE)$Package)
  app_packages <- setdiff(app_packages, packages_to_not_install_from_cran)

  # try installing all cran packages
  setNames(
    vapply(app_packages, cached_install_cran_pkg, logical(1)),
    app_packages
  )
}


install_cran_packages_safely <- function(packages) {
  # if some other packages are loaded already depend upon it, the pkg is not installed from CRAN
  callr::r(
    function(to_install_, options_) {
      options(options_)
      lapply(to_install_, function(pkg_to_install) {
        try({
          utils::remove.packages(pkg_to_install)
        }, silent = TRUE)
      })
      # force install all the things from CRAN
      utils::install.packages(to_install_, dependencies = TRUE)
    },
    list(
      to_install_ = packages,
      options_ = options()
    ),
    show = TRUE
  )

}

install_binary_or_source <- function(package) {

  install_cran_ <- function(type) {
    did_not_install <- function(e) {
      message("Error installing ", type, " package with shinycoreci: ", package, "\n", e)
      FALSE
    }
    tryCatch(
      {
        message("Installing ", type, " package with shinycoreci: ", package)
        remotes::install_cran(package, type = type)
        TRUE
      },
      warning = did_not_install,
      error = did_not_install
    )
  }

  did_install <- install_cran_("binary")
  if (did_install) {
    return(TRUE)
  }

  install_cran_("source")
}

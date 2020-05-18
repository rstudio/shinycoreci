

#' Install direct \pkg{shinycoreci} dependencies
#'
#' If something goes wrong, default to installing `shinycoreci` from GitHub. Then try installing the dependencies again. See the examples.
#'
#' @inheritParams test_shinyjster
#' @param try_again Logical to determine if RStudio IDE should try again after a failure
#' @export
#' @examples
#' \dontrun{remotes::install_github("rstudio/shinycoreci")
#' shinycoreci::install_exact_shinycoreci_deps("apps")}
install_exact_shinycoreci_deps <- function(dir = "apps", try_again = TRUE) {

  installed_something <- FALSE

  # Make sure shinycoreci is up to date
  message("Update shinycoreci...", appendLF = FALSE)
  shinycoreci_info <- remotes::package_deps("shinycoreci")
  if (shinycoreci_info$diff < 0) {
    installed_something <- TRUE
    message("") # closs off line
    remotes__update_package_deps(shinycoreci_info, upgrade = TRUE, dependencies = TRUE)
  } else {
    message(" OK")
  }

  # all remotes based from shinycoreci
  message("Gathering recursive remotes...", appendLF = FALSE)
  scci_remotes_all <- tryCatch({
    ans <- remote_deps_recursive("shinycoreci")
    message(" OK")
    ans
  }, error = function(e) {
    # a shinycoreci dependency could not be found. Reinstall shinycoreci
    message("")
    message("Reinstalling shinycoreci. Not all dependencies found")
    installed_something <<- TRUE
    remotes::install_github(repo_from_remote(shinycoreci_info$remote[[1]]), upgrade = TRUE, force = TRUE)
    remote_deps_recursive("shinycoreci")
  })
  scci_remotes <- unique(unname(unlist(scci_remotes_all)))

  message("Gathering dependency information...", appendLF = FALSE)
  scci_dev_deps <- app_deps(dir)
  message(" OK")

  # determine apps to check
  should_be_cran_only <- setdiff(scci_dev_deps$package, c("shinycoreci", scci_remotes))
  should_be_github_only <- scci_remotes

  # check cran pkgs
  message("Checking all non-Remote packages are CRAN packages...", appendLF = FALSE)
  cran_info <- scci_dev_deps[scci_dev_deps$package %in% should_be_cran_only, ]
  # get packages that are currently not cran sources or are behind in version
  should_install_cran <- (!cran_info$is_cran) | (cran_info$diff < 0)
  if (any(!cran_info$is_cran)) {
    installed_something <- TRUE
    to_install <- cran_info$package[should_install_cran]
    message("") # close off line
    message("Installing CRAN pkgs: ", paste0("'", to_install, "'", collapse = ", "))
    # make sure the old package is gone!
    # if some other packages are loaded already depend upon it, the pkg is not installed from CRAN
    callr::r(
      function(to_install_) {
        lapply(to_install_, function(pkg_to_install) {
          try({
            utils::remove.packages(pkg_to_install)
          }, silent = TRUE)
        })
        # force install all the things from CRAN
        utils::install.packages(to_install_, dependencies = TRUE)
      },
      list(to_install_ = to_install),
      show = TRUE
    )
  } else {
    message(" OK")
  }

  message("Checking all Remotes are installed from GitHub...", appendLF = FALSE)
  remotes_info <- scci_dev_deps[scci_dev_deps$package %in% should_be_github_only, ]
  # check if packages are installed from github or are behind
  if (any(remotes_info$is_cran)) {
    message("") # close off line
    installed_something <- TRUE
    message("Re-installing some packages as these Remotes were not installed from GitHub")
    print(tibble::as_tibble(remotes_info[remotes_info$is_cran, ]))

    currently_cran_needs_github_pkgs <- remotes_info$package[remotes_info$is_cran]
    mapply(
      names(scci_remotes_all),
      scci_remotes_all,
      FUN = function(pkg, github_deps) {
        if (!any(currently_cran_needs_github_pkgs %in% github_deps)) {
          return()
        }
        # get the remote of the currently installed github package
        remote <- scci_dev_deps$remote[scci_dev_deps$package == pkg][[1]]
        # reinstall it to bring in all missing dependencies
        remotes::install_github(repo_from_remote(remote), force = TRUE, upgrade = TRUE)
      }
    )
  } else {
    message(" OK")
  }

  message("Checking GitHub packages are up to date...", appendLF = FALSE)
  should_update_github <- (remotes_info$diff < 0) & (!remotes_info$is_cran)
  if (any(should_update_github)) {
    message("") # close off line
    installed_something <- TRUE
    message("Updating GitHub packages:")
    print(tibble::as_tibble(remotes_info[should_update_github, ]))
    remotes__update_package_deps(remotes_info[should_update_github, ], upgrade = TRUE, dependencies = TRUE)
  } else {
    message(" OK")
  }

  if (installed_something) {
    if (isTRUE(try_again) && rstudioapi::isAvailable()) {
      func <- paste0("shinycoreci::install_exact_shinycoreci_deps(\"", dir, "\", try_again = FALSE)")
      message("Restarting RStudio to try again in a fresh session")
      message("Note: This next function call should pass!!")
      rstudioapi::restartSession(func)
      return(invisible(FALSE))
    }

    func <- paste0("shinycoreci::install_exact_shinycoreci_deps(\"", dir, "\")")
    stop(
      "Some packages were overwritten. Please restart your R session and run this function again.",
      "\n\n\t", func, "\n\n",
      call. = FALSE
    )
  }

  message("Session is up to date!")
  invisible(TRUE)
}


## Gather all names of packages that should be installed by github
## , given the information already installed
## If a dependency package remote is not found because a parent is not correct
## , then the parent will be installed due to a bad remote value (which also installs the dep package)
remote_deps_recursive <- function(package_name) {

  ret <- list()

  remote_deps_recursive_ <- function(pkg_name) {
    if (!is.null(ret[[pkg_name]])) {
      return(ret[[pkg_name]])
    }
    rem_deps <- remotes__remote_deps(
      remotes__load_pkg_description(system.file(package = pkg_name))
    )

    # store
    ret[[pkg_name]] <<- rem_deps$package

    # call on those remotes
    unlist(lapply(rem_deps$package, remote_deps_recursive_))

    # return
    ret[[pkg_name]]
  }


  remote_deps_recursive_(package_name)

  ret
}


repo_from_remote <- function(remote_obj) {
  if (!inherits(remote_obj, "github_remote")) {
    utils::str(remote_obj)
    stop("not a remote!")
  }
  paste0(
    remote_obj$username,
    "/",
    remote_obj$repo,
    "@",
    remote_obj$branch %||% "master"
  )
}

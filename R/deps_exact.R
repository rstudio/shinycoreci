

#' Install direct \pkg{shinycoreci} dependencies
#'
#' @inheritParams test_shinyjster
#' @param try_again Logical to determine if RStudio IDE should try again after a failure
#' @export
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
  scci_remotes <- remote_deps_recursive("shinycoreci")
  message(" OK")

  message("Gathering dependency information...", appendLF = FALSE)
  scci_dev_deps <- app_deps(dir)
  message(" OK")

  # determine apps to check
  should_be_cran_only <- setdiff(scci_dev_deps$package, c("shinycoreci", scci_remotes))
  should_be_github_only <- scci_remotes

  # check cran pkgs
  message("Checking CRAN packages...", appendLF = FALSE)
  cran_info <- scci_dev_deps[scci_dev_deps$package %in% should_be_cran_only, ]
  # get packages that are currently not cran sources or are behind in version
  should_install_cran <- (!cran_info$is_cran) | (cran_info$diff < 0)
  if (any(should_install_cran)) {

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
        # install all the things from CRAN
        remotes::install_cran(to_install_, upgrade = TRUE, force = TRUE, dependencies = TRUE)
      },
      list(to_install_ = to_install),
      show = TRUE
    )
  } else {
    message(" OK")
  }

  message("Checking GitHub packages...", appendLF = FALSE)
  remotes_info <- scci_dev_deps[scci_dev_deps$package %in% should_be_github_only, ]
  # check if packages are installed from github or are behind
  should_install_github <- remotes_info$is_cran | (remotes_info$diff < 0)
  if (any(should_install_github)) {
    message("") # close off line
    installed_something <- TRUE
    print(remotes_info)
    remotes__update_package_deps(remotes_info, upgrade = TRUE, dependencies = TRUE)
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

  has_calculated <- list()

  remote_deps_recursive_ <- function(pkg_name) {
    if (isTRUE(has_calculated[[pkg_name]])) {
      return(NULL)
    }
    rem_deps <- remotes__remote_deps(
      remotes__load_pkg_description(system.file(package = pkg_name))
    )
    unique(c(
      rem_deps$package,
      unlist(lapply(rem_deps$package, remote_deps_recursive_))
    ))
  }

  remote_deps_recursive_(package_name)
}

is_installed <- function(package) {
  nzchar(system.file(package = package))
}

suggested_pkgs <- function() {
  desc_info <- packageDescription("shinycoreci")
  desc_file <- attr(desc_info, "file")
  renv::dependencies(desc_file, quiet = TRUE)
}



req_pkg <- local({

  err_stop <- function(...) {
    stop(
      ..., "\n",
      "To install the latest, call `shinycoreci::install_exact_shinycoreci_deps()` within `shinycoreci-apps` repo"
    )
  }

  function(package, suggested_packages = suggested_pkgs()) {
    if (!is_installed(package)) {
      err_stop(package, " is not installed and is required by `shinycoreci`")
    }



    # get the package info line
    suggested_package_info <- as.list(suggested_packages[suggested_packages$Package == package, ][1, ])

    version <- suggested_package_info$Version

    if (nchar(version) > 0) {
      require <- suggested_package_info$Require
      desc_version <- package_version(version)
      installed_version <- utils::packageVersion(package)

      if (
        # if required version is greater than installed version
        (require == ">=" && !(installed_version >= desc_version)) ||
        # if the required version is greather than or equal to the installed version
        (require == ">" && !(installed_version > desc_version))
      ) {
        err_stop("Insufficient version found for package: ", package, ". Need `", require, " ", desc_version, "`. Have `", installed_version, "`")
      }
    }

    invisible(TRUE)
  }
})

# require all shinyverse packages.
# If there is an insufficient version, reinstall shinycoreci and it's suggested dependencies
validate_core_pkgs <- function() {
  suggested_packages <- suggested_pkgs()
  lapply(suggested_packages$Package, req_pkg, suggested_packages = suggested_packages)

  invisible(TRUE)
}

validate_exact_deps <- function(dir = "apps", apps = apps_runtests(dir), update_pkgs = TRUE, assert = interactive()) {
  # install all the packages
  if (isTRUE(update_pkgs)) {
    # do not try to
    install_exact_shinycoreci_deps(dir = dir, apps = apps, assert = assert)
  }
  validate_core_pkgs()
}


# tryCatch({
# }, error = function(e) {
#   if (!isTRUE(install_missing)) {
#     stop(e)
#   }
#   message('', e)
#   message("Installing all of shinycoreci")
#   shinycoreci_info <- remotes::package_deps("shinycoreci")
#   remotes__update_package_deps(shinycoreci_info, upgrade = TRUE, dependencies = FALSE)
# })

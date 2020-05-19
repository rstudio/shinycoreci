is_installed <- function(package) {
  nzchar(system.file(package = package))
}

suggested_pkgs <- local({
  val <- NULL

  function() {
    # if (!is.null(val)) {
    #   return(val)
    # }

    val <<- strsplit(
      unname(
        read.dcf(system.file("DESCRIPTION", package = "shinycoreci"), fields = "Suggests")[1, 1]
      ),
      ",\\s*"
    )[[1]]

    val
  }
})


req_pkg <- local({

  err_stop <- function(...) {
    stop(
      ..., "\n",
      "To install the latest, call `shinycoreci::install_exact_shinycoreci_deps()` within `shinycoreci-apps` repo"
    )
  }

  function(package) {
    if (!is_installed(package)) {
      err_stop(package, " is not installed and is required by `shinycoreci`")
    }

    # get the package info line
    suggested_package <- grep(package, suggested_pkgs(), value = TRUE, fixed = TRUE)

    # version number match
    version <-
      regmatches(
        suggested_package,
        regexec(base::.standard_regexps()$valid_numeric_version, suggested_package)
      )[[1]][1]

    if (!is.na(version) && nchar(version) > 0) {
      # required version is greater than installed version
      if (package_version(version) > utils::packageVersion(package)) {
        err_stop("Insufficient version found for package: ", package, ". Need `", suggested_package, "`. Have `", utils::packageVersion(package), "`")
      }
    }

    invisible(TRUE)
  }
})

# require all shinyverse packages.
# If there is an insufficient version, reinstall shinycoreci and it's suggested dependencies
req_core_pkgs <- function(update_pkgs = TRUE, install_missing = TRUE) {
  if (!isTRUE(update_pkgs)) {
    return()
  }

  tryCatch({
    pkgs <- suggested_pkgs()
    pkgs <- vapply(strsplit(pkgs, " "), `[[`, character(1), 1)
    lapply(pkgs, req_pkg)
  }, error = function(e) {
    if (!isTRUE(install_missing)) {
      stop(e)
    }
    message('', e)
    message("Installing all of shinycoreci")
    shinycoreci_info <- remotes::package_deps("shinycoreci")
    remotes__update_package_deps(shinycoreci_info, upgrade = TRUE, dependencies = TRUE)
  })

  invisible(TRUE)
}

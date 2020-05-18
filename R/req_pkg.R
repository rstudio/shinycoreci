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

req_core_pkgs <- function() {
  pkgs <- suggested_pkgs()
  pkgs <- vapply(strsplit(pkgs, " "), `[[`, character(1), 1)
  lapply(pkgs, req_pkg)

  invisible(TRUE)
}

#' Install app dependencies
#'
#' @param dir Directory containing apps
#' @export
install_app_deps <- function(dir = "apps") {
  deps <- app_deps(dir)
  remotes__update_package_deps(deps, upgrade = TRUE)
  invisible(deps)
}

#' @rdname install_app_deps
#' @export
app_deps <- function(dir = "apps") {
  combine_deps <- triple_colon("remotes", "combine_deps")

  # First get packages specified in DESCRIPTION files - these will tend to be
  # listed in Remotes.
  app_dirs <- shiny_app_dirs(dir)
  app_dirs <- Filter(x = app_dirs, function(app_dir) {
    file.exists(file.path(app_dir, "DESCRIPTION")) && (!identical(basename(app_dir), ".git"))
  })
  # make sure shinycoreci deps are installed
  app_dirs <- c(system.file(package = "shinycoreci"), app_dirs)
  desc_deps <- lapply(app_dirs, remotes::dev_package_deps)
  desc_deps <- Filter(x = desc_deps, function(dep_info) nrow(dep_info) != 0)

  # Find the dependencies from application code
  renv_deps <- renv::dependencies(dir, quiet = TRUE)
  app_deps <- remotes::package_deps(unique(renv_deps$Package))

  if (length(desc_deps) == 0) {
    return(app_deps)

  } else {
    if (length(desc_deps) == 1) {
      desc_deps <- desc_deps[[1]]
    } else {
      warning("`combine_deps` does not combine independent deps!")
      desc_deps <- Reduce(combine_deps, desc_deps[-1], desc_deps[[1]])
    }
    combine_deps(app_deps, desc_deps)
  }
}

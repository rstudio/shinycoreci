#' Install app dependencies
#'
#' @param dir Directory containing apps
#' @export
install_app_deps <- function(dir = "apps") {
  deps <- app_deps(dir)
  remotes__update_package_deps(deps, upgrade = TRUE, dependencies = TRUE)
  invisible(deps)
}

#' @rdname install_app_deps
#' @export
app_deps <- function(dir = "apps") {
  # First get packages specified in DESCRIPTION files - these will tend to be
  # listed in Remotes.
  app_dirs <- shiny_app_dirs(dir)
  app_dirs <- Filter(x = app_dirs, function(app_dir) {
    file.exists(file.path(app_dir, "DESCRIPTION")) && (!identical(basename(app_dir), ".git"))
  })
  # make sure shinycoreci deps are installed
  app_dirs <- c(system.file(package = "shinycoreci"), app_dirs)
  desc_deps_list <- lapply(app_dirs, remotes::dev_package_deps, dependencies = TRUE)
  desc_deps_list <- Filter(x = desc_deps_list, function(dep_info) nrow(dep_info) != 0)

  # Find the dependencies from application code
  renv_deps <- renv::dependencies(dir, quiet = TRUE)
  app_deps <- remotes::package_deps(unique(renv_deps$Package), dependencies = TRUE)

  # Get the unique package information from all locations
  unique(Reduce(rbind, c(desc_deps_list, list(app_deps)), NULL))
}

#' Install app dependencies
#'
#' @param dir Directory containing apps
#' @param apps apps to find the dependencies of
#' @param include_shinycoreci Logical value which determines if shinycoreci should be included
#' @export
install_app_deps <- function(dir = "apps", apps = apps_runtests(dir), include_shinycoreci = TRUE) {
  deps <- app_deps(dir = dir, apps = apps, include_shinycoreci = include_shinycoreci)
  remotes__update_package_deps(deps, upgrade = TRUE)
  invisible(deps)
}

#' @rdname install_app_deps
#' @export
app_deps <- function(dir = "apps", apps = apps_runtests(dir), include_shinycoreci = TRUE) {

  # First get packages specified in DESCRIPTION files - these will tend to be
  # listed in Remotes.
  app_dirs <- file.path(dir, apps)
  desc_app_dirs <- Filter(x = app_dirs, function(app_dir) {
    file.exists(file.path(app_dir, "DESCRIPTION")) && (!identical(basename(app_dir), ".git"))
  })
  # make sure shinycoreci deps are installed
  desc_deps_list <- append(
    # gather all deps from shinycoreci
    if (isTRUE(include_shinycoreci)) {
      lapply(system.file(package = "shinycoreci"), remotes::dev_package_deps, dependencies = TRUE)
    } else {
      list()
    },
    lapply(desc_app_dirs, remotes::dev_package_deps)
  )
  desc_deps_list <- Filter(x = desc_deps_list, function(dep_info) nrow(dep_info) != 0)

  # Find the dependencies from application code
  renv_deps <- unique(renv::dependencies(app_dirs, quiet = TRUE)$Package)
  if (!isTRUE(include_shinycoreci)) {
    renv_deps <- setdiff(renv_deps, "shinycoreci")
  }
  remotes_app_deps <- remotes::package_deps(renv_deps)

  # Get the unique package information from all locations
  unique(do.call(rbind, c(desc_deps_list, list(remotes_app_deps))))
}

#' Install app dependencies
#'
#' @param dir Directory containing apps
#' @export
install_app_deps <- function(dir = "apps") {
  deps <- app_deps(dir)
  lapply(deps, triple_colon("remotes", "update.package_deps"), upgrade = TRUE)
}

#' @rdname install_app_deps
#' @export
app_deps <- function(dir = "apps") {
  app_dirs <- file.path(dir, dir(dir))
  app_dirs <- Filter(x = app_dirs, function(app_dir) {
    file.exists(file.path(app_dir, "DESCRIPTION"))
  })
  deps <- lapply(app_dirs, remotes::dev_package_deps)
  deps <- Filter(x = deps, function(dep_info) nrow(dep_info) != 0)
  deps
}

triple_colon <- function(pkg, name) {
  getNamespace(pkg)[[name]]
}


# remotes__update_package_deps <- function(...) {
#   triple_colon("remotes", "update.package_deps")(...)
# }
# remotes__remote_deps <- function(...) {
#   triple_colon("remotes", "remote_deps")(...)
# }
# remotes__load_pkg_description <- function(...) {
#   triple_colon("remotes", "load_pkg_description")(...)
# }


base__library <- function(...) {
  triple_colon("base", "library")(...)
}

testthat__snapshot_meta <- function(...) {
  triple_colon("testthat", "snapshot_meta")(...)
}

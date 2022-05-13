is_installed <- function(package) {
  nzchar(system.file(package = package))
}
check_installed <- function(package) {
  if (!is_installed(package)) {
    stop(package, " is not installed and is required by `shinycoreci`")
  }
}



shinycoreci_is_local <- function() {
  # If `.git` folder exists, we can guess it is in dev mode
  dir.exists(
    file.path(
      dirname(system.file("DESCRIPTION", package = "shinycoreci")),
      ".git"
    )
  )
}


# Used in GHA workflow
install_shinyverse_local <- function(
  ...,
  # Install into normal libpath so caching is automatically handled
  libpath = .libPaths()[1]
) {
  install_shinyverse(..., libpath = libpath)
}

#' @noRd
#' @return lib path being used
install_shinyverse <- function(
  install = TRUE,
  validate_loaded = TRUE,
  upgrade = TRUE, # pak::pkg_install(upgrade = FALSE)
  dependencies = NA, # pak::pkg_install(dependencies = NA)
  extra_packages = NULL,
  install_apps_deps = TRUE,
  libpath = shinyverse_libpath()
) {
  if (!isTRUE(install)) return(.libPaths()[1])

  # Make sure none of the shinyverse is loaded into namespace
  if (isTRUE(validate_loaded)) {
    shiny_search <- paste0("package:", shinyverse_pkgs)
    if (any(shiny_search %in% search())) {
      bad_namespaces <- shinyverse_pkgs[shiny_search %in% search()]
      stop(
        "The following packages are already loaded:\n",
        paste0("* ", bad_namespaces, "\n", collapse = ""),
        "Please restart and try again"
      )
    }
  }

  # Remove shinyverse
  pak_apps_deps <-
    if (isTRUE(install_apps_deps)) {
      paste0("any::", apps_deps[!(apps_deps %in% c(shinyverse_pkgs, "shinycoreci", "shinycoreciapps"))])
    } else {
      NULL
    }

  # Load pak into current namespace
  pkgs <- c(shinyverse_remotes, pak_apps_deps, extra_packages)
  message("Installing shinyverse and app deps: ", libpath)
  if (!is.null(extra_packages)) {
    message("Extra packages:\n", paste0("* ", extra_packages, collapse = "\n"))
  }
  callr::r(
    function(pkgs, lib, upgrade, dependencies) {
      # Performing a leap of faith that pak is installed.
      # Avoids weird installs when using pak to install shinycoreci
      stopifnot(utils::packageVersion("pak") >= "0.3.0")
      pak__pkg_install <- utils::getFromNamespace("pkg_install", "pak")
      pak__pkg_install(
        pkgs,
        lib = lib,
        upgrade = upgrade,
        dependencies = dependencies,
        ask = FALSE # Not interactive, so don't ask
      )
    },
    list(
      pkgs = pkgs,
      lib = libpath,
      upgrade = upgrade,
      dependencies = dependencies
    ),
    show = TRUE,
    spinner = TRUE # helps with CI from timing out
  )

  return(libpath)
}

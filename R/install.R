is_installed <- function(package, libpath = .libPaths()[1]) {
  nzchar(system.file(package = package, lib.loc = libpath))
}
check_installed <- function(package, libpath = .libPaths()[1]) {
  if (!is_installed(package, libpath = libpath)) {
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
  libpath = .libPaths()[1],
  install_apps_deps = FALSE
) {
  install_shinyverse(..., libpath = libpath, install_apps_deps = install_apps_deps)
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

  install_pkgs_with_callr(pkgs, libpath = libpath, upgrade = upgrade, dependencies = dependencies)
  return(libpath)
}


# Install missing dependencies given an app name
# If more than one app name is provided, run through all of them individually
## Method used by GHA cache warming
install_missing_app_deps <- function(app_name = names(apps_deps_map), libpath = .libPaths()[1], upgrade = FALSE, dependencies = NA, ..., recursing = FALSE) {
  if (!isTRUE(recursing)) {
    install_troublesome_pkgs(libpath = libpath)
  }
  if (length(app_name) > 1) {
    for (app_name_val in app_name) {
      install_missing_app_deps(app_name_val, libpath = libpath, upgrade = upgrade, dependencies = dependencies, recursing = TRUE)
    }
    return(invisible())
  }

  app_name <- resolve_app_name(app_name)

  app_deps <- apps_deps_map[[app_name]]

  install_missing_pkgs(app_deps, libpath = libpath, upgrade = upgrade, dependencies = dependencies)
  deps <- Filter(app_deps, f = function(dep) !is_installed(dep, libpath = libpath))
  if (length(deps) > 0) {
    message("Installing missing packages: ", paste0(deps, collapse = ", "))
    install_pkgs_with_callr(deps, libpath = libpath, upgrade = upgrade, dependencies = dependencies)
  }

  invisible()
}

# packages_to_install is what is really installed given the value of packages
install_missing_pkgs <- function(packages, libpath = .libPaths()[1], upgrade = FALSE, dependencies = NA, packages_to_install = packages) {
  packages_to_install <- unlist(Map(
    packages,
    packages_to_install,
    f = function(package, value) {
      if (!is_installed(package, libpath = libpath)) {
        value
      } else {
        NULL
      }
    }
  ))
  if (length(packages_to_install) > 0) {
    message("Installing missing packages: ", paste0(packages_to_install, collapse = ", "))
    install_pkgs_with_callr(packages_to_install, libpath = libpath, upgrade = upgrade, dependencies = dependencies)
  }

  invisible()
}

install_pkgs_with_callr <- function(
  packages,
  libpath = .libPaths()[1],
  upgrade = TRUE, # pak::pkg_install(upgrade = FALSE)
  dependencies = NA # pak::pkg_install(dependencies = NA)
) {
  callr::r(
    function(packages, lib, upgrade, dependencies) {
      # Performing a leap of faith that pak is installed.
      # Avoids weird installs when using pak to install shinycoreci
      stopifnot(utils::packageVersion("pak") >= "0.3.0")
      pak__pkg_install <- utils::getFromNamespace("pkg_install", "pak")
      pak__pkg_install(
        packages,
        lib = lib,
        ask = FALSE, # Not interactive, so don't ask
        upgrade = upgrade,
        dependencies = dependencies
      )
    },
    list(
      packages = packages,
      lib = libpath,
      upgrade = upgrade,
      dependencies = dependencies
    ),
    show = TRUE,
    spinner = TRUE # helps with CI from timing out
  )
}





# This logic should mimic `./gihub/internal/install-shinyvers/action.yaml` logic
install_troublesome_pkgs <- function(libpath = .libPaths()[1]) {

  # Get R version like `"4.2"`
  short_r_version <- sub("\\.\\d$", "", as.character(getRversion()))

  if (is_mac()) {
    switch(short_r_version,
      "4.2" = {
        install_missing_pkgs(
          packages = "XML",
          packages_to_install = "XML",
          libpath = libpath
        )
      }
    )
  }

  if (is_linux()) {
    switch(short_r_version,
      "4.2" = {
        install_missing_pkgs(
          packages = "XML",
          packages_to_install = "XML",
          libpath = libpath
        )
      },
      "3.6" = {
        install_missing_pkgs(
          packages = "rjson",
          packages_to_install = "url::https://cran.r-project.org/src/contrib/Archive/rjson/rjson_0.2.20.tar.gz",
          libpath = libpath
        )
      },
      "3.5" = {
        install_missing_pkgs(
          packages = c("rjson", "radiant"),
          packages_to_install = c(
            "url::https://cran.r-project.org/src/contrib/Archive/rjson/rjson_0.2.20.tar.gz",
            "url::https://cran.r-project.org/src/contrib/Archive/radiant/radiant_1.3.2.tar.gz"
          ),
          libpath = libpath
        )
      }
    )
  }
  if (is_windows()) {
    switch(short_r_version,
      "3.5" = {
        # https://github.com/r-spatial/s2/issues/140
        # Once s2 > 1.0.7 is released, this can be removed... hopefully
        install_missing_pkgs(
          packages = "s2",
          packages_to_install = "r-spatial/s2",
          libpath = libpath
        )

        # Can't install from source on windows; Missing many libraries
        install_missing_pkgs(
          packages = "sf",
          packages_to_install = "url::https://cran.r-project.org/bin/windows/contrib/3.5/sf_0.9-2.zip",
          libpath = libpath
        )
      }
    )
  }
  invisible()
}

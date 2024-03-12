# This method should **not** be used outside of this file
# Only check if the package is installed in the `libpath`.
# `package` may be installed in another libpath
is_installed <- function(package, libpath) {
  nzchar(system.file(package = package, lib.loc = libpath))
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


# # Used in GHA workflow
# install_shinyverse_local <- function(
#     ...,
#     # Install into normal libpath so caching is automatically handled
#     libpath = .libPaths()[1],
#     install_apps_deps = FALSE) {
#   install_shinyverse(..., libpath = libpath, install_apps_deps = install_apps_deps)
# }

# #' @noRd
# #' @return lib path being used
# install_shinyverse_old <- function(
#     install = TRUE,
#     validate_loaded = TRUE,
#     upgrade = TRUE, # pak::pkg_install(upgrade = FALSE)
#     dependencies = NA, # pak::pkg_install(dependencies = NA)
#     extra_packages = NULL,
#     install_apps_deps = TRUE,
#     libpath = shinycoreci_libpath()) {
#   if (!isTRUE(install)) {
#     return(.libPaths()[1])
#   }

#   # Make sure none of the shinyverse is loaded into namespace
#   if (isTRUE(validate_loaded)) {
#     shiny_search <- paste0("package:", shinyverse_pkgs)
#     if (any(shiny_search %in% search())) {
#       bad_namespaces <- shinyverse_pkgs[shiny_search %in% search()]
#       stop(
#         "The following packages are already loaded:\n",
#         paste0("* ", bad_namespaces, "\n", collapse = ""),
#         "Please restart and try again"
#       )
#     }
#   }

#   # Remove shinyverse
#   pak_apps_deps <-
#     if (isTRUE(install_apps_deps)) {
#       apps_deps[!(apps_deps %in% c("shinycoreci"))]
#     } else {
#       NULL
#     }

#   # Load pak into current namespace
#   pkgs <- c(pak_apps_deps, extra_packages)
#   message("Install libpath: ", libpath)
#   message("Installing pkgs:\n", paste0("* ", pkgs, collapse = "\n"))
#   # if (!is.null(extra_packages)) {
#   #   message("Extra packages:\n", paste0("* ", extra_packages, collapse = "\n"))
#   # }

#   install_pkgs_with_callr(pkgs, libpath = libpath, upgrade = upgrade, dependencies = dependencies)
#   return(libpath)
# }

## Used in GHA workflow
# Install missing dependencies given an app name
# If more than one app name is provided, run through all of them individually
install_missing_app_deps <- function(
    app_name = names(apps_deps_map),
    libpath = .libPaths()[1],
    upgrade = FALSE,
    dependencies = NA
    # ,
    # ...,
    # recursing = FALSE
    ) {
  # if (!isTRUE(recursing)) {
  #   install_troublesome_pkgs_old(libpath = libpath)
  # }
  app_deps <-
    if (length(app_name) > 1) {
      unique(unlist(
        lapply(app_name, function(app_name_val) {
          apps_deps_map[[resolve_app_name(app_name_val)]]
        })
      ))
    } else {
      apps_deps_map[[resolve_app_name(app_name)]]
    }


  install_missing_pkgs(
    app_deps,
    libpath = libpath,
    upgrade = upgrade,
    dependencies = dependencies
  )

  invisible()
}



installed_pkgs <- new.env(parent = emptyenv())


# packages_to_install is what is really installed given the value of packages
install_missing_pkgs <- function(
    packages,
    libpath = .libPaths()[1],
    upgrade = FALSE,
    dependencies = NA,
    packages_to_install = packages) {

  pkgs_to_install <- packages_to_install[!(packages_to_install %in% names(installed_pkgs))]

  if (length(pkgs_to_install) > 0) {
    message(
      "Installing missing packages: ",
      paste0(pkgs_to_install, collapse = ", ")
    )
    install_pkgs_with_callr(
      pkgs_to_install,
      libpath = libpath,
      upgrade = upgrade,
      dependencies = dependencies
    )
    # Update the installed status as an install error was not thrown
    for (package in pkgs_to_install) {
      # Set in environment
      installed_pkgs[[package]] <- TRUE
    }
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
      options(repos = c(
        # Use the shinycoreci universe to avoid GH rate limits!
        "AAA" = "https://posit-dev-shinycoreci.r-universe.dev",
        getOption("repos", c("CRAN" = "https://cloud.r-project.org"))
      ))

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





# # This logic should mimic `./gihub/internal/install-shinyvers/action.yaml` logic
# install_troublesome_pkgs_old <- function(libpath = .libPaths()[1]) {
#   # Get R version like `"4.2"`
#   short_r_version <- sub("\\.\\d$", "", as.character(getRversion()))

#   if (is_mac()) {
#     switch(short_r_version,
#       "4.2" = {
#         install_missing_pkgs(
#           packages = "XML",
#           packages_to_install = "XML",
#           libpath = libpath
#         )
#       }
#     )
#   }

#   if (is_linux()) {
#     switch(short_r_version,
#       "4.2" = {
#         install_missing_pkgs(
#           packages = "XML",
#           packages_to_install = "XML",
#           libpath = libpath
#         )
#       },
#       "3.6" = {
#         install_missing_pkgs(
#           packages = "rjson",
#           packages_to_install = "url::https://cran.r-project.org/src/contrib/Archive/rjson/rjson_0.2.20.tar.gz",
#           libpath = libpath
#         )
#       }
#     )
#   }

#   if (is_windows()) {
#     switch(short_r_version,
#       "4.0" = {
#         install_missing_pkgs(
#           packages = "terra",
#           packages_to_install = "url::https://cloud.r-project.org/bin/windows/contrib/4.0/terra_1.5-21.zip",
#           libpath = libpath
#         )
#       },
#       "3.6" = {
#         install_missing_pkgs(
#           packages = "terra",
#           packages_to_install = "url::https://cloud.r-project.org/bin/windows/contrib/3.6/terra_1.2-5.zip",
#           libpath = libpath
#         )
#       }
#     )
#   }

#   invisible()
# }

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



# Attempt to set up all the packages in the shinyverse, even if they are not directly depended upon.
attempt_to_install_universe <- function(
  ...,
  libpath = .libPaths()[1],
  verbose = TRUE
) {
  stopifnot(length(list(...)) == 0)

  tryCatch(
    {
      install_missing_pkgs(
        shinyverse_pkgs,
        libpath = libpath,
        upgrade = TRUE,
        prompt = "Installing shinyverse packages: ",
        verbose = verbose
      )
    },
    error = function(e) {
      # Couldn't install all at once, Installing individually
      message("Failed to install shinyverse packages in a single attempt. Error: ", e)
      message("Installing shinyverse packages individually!")
      Map(seq_along(shinyverse_pkgs), shinyverse_pkgs, f = function(i, pkg) {
        tryCatch(
          {
            install_missing_pkgs(
              pkg,
              libpath = libpath,
              upgrade = TRUE,
              prompt = paste0("[", i, "/", length(shinyverse_pkgs), "] Installing shinyverse package: "),
              verbose = verbose
            )
          },
          error = function(e) {
            message("Failed to install ", pkg, " from universe")
          }
        )
      })
    }
  )

}



## Used in GHA workflow
# Install missing dependencies given an app name
# If more than one app name is provided, run through all of them individually
install_missing_app_deps <- function(
    app_name = names(apps_deps_map),
    ...,
    libpath = .libPaths()[1],
    upgrade = FALSE,
    dependencies = NA,
    verbose = TRUE
    ) {
  stopifnot(length(list(...)) == 0)

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
    dependencies = dependencies,
    verbose = verbose
  )

  invisible()
}



installed_pkgs <- new.env(parent = emptyenv())


# packages is what is really installed given the value of packages
install_missing_pkgs <- function(
    packages,
    ...,
    libpath = .libPaths()[1],
    upgrade = FALSE,
    dependencies = NA,
    prompt = "Installing missing packages: ",
    verbose = TRUE
) {
  stopifnot(length(list(...)) == 0)

  pkgs_to_install <- packages[!(packages %in% names(installed_pkgs))]

  if (length(pkgs_to_install) > 0) {
    message(
      prompt,
      paste0(pkgs_to_install, collapse = ", ")
    )
    message("libpath: ", libpath)

    install_pkgs_with_callr(
      pkgs_to_install,
      libpath = libpath,
      upgrade = upgrade,
      dependencies = dependencies,
      verbose = verbose
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
    ...,
    libpath = .libPaths()[1],
    upgrade = TRUE, # pak::pkg_install(upgrade = FALSE)
    dependencies = NA, # pak::pkg_install(dependencies = NA)
    verbose = TRUE
    ) {
  stopifnot(length(list(...)) == 0)
  callr::r(
    function(shinyverse_cran_url, packages, upgrade, dependencies) {
      options(repos = c(
        # Use the shinycoreci universe to avoid GH rate limits!
        "AAA" = shinyverse_cran_url,
        getOption("repos", c("CRAN" = "https://cloud.r-project.org"))
      ))

      # Performing a leap of faith that pak is installed.
      # Avoids weird installs when using pak to install shinycoreci
      stopifnot(utils::packageVersion("pak") >= "0.3.0")
      pak__pkg_install <- utils::getFromNamespace("pkg_install", "pak")
      pak__pkg_install(
        packages,
        ask = FALSE, # Not interactive, so don't ask
        upgrade = upgrade,
        dependencies = dependencies
      )
    },
    list(
      shinyverse_cran_url = shinyverse_cran_url,
      packages = packages,
      upgrade = upgrade,
      dependencies = dependencies
    ),
    show = verbose,
    libpath = libpath,
    supervise = TRUE,
    spinner = TRUE # helps with CI from timing out
  )
}

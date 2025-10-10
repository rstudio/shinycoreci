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

shinyverse_repos_option <- function() {
  RSPM <- Sys.getenv("RSPM")
  c(
    # Use the shinycoreci universe to avoid GH rate limits!
    "AAA" = shinyverse_cran_url,
    if (nzchar(RSPM)) c("RSPM" = RSPM),
    getOption("repos", c("CRAN" = "https://cloud.r-project.org"))
  )
}


# # Attempt to set up all the packages in the shinyverse, even if they are not directly depended upon.
# attempt_to_install_universe <- function(
#   ...,
#   libpath = .libPaths()[1],
#   verbose = TRUE
# ) {
#   return()
#   stopifnot(length(list(...)) == 0)

#   # pkgs <- paste0(shinyverse_pkgs, "?source")

#   tryCatch(
#     {
#       install_missing_pkgs(
#         pkgs,
#         libpath = libpath,
#         prompt = "Installing shinyverse packages: ",
#         verbose = verbose
#       )
#     },
#     error = function(e) {
#       # Couldn't install all at once, Installing individually
#       message("Failed to install shinyverse packages in a single attempt. Error: ", e)
#       message("Installing shinyverse packages individually!")
#       Map(seq_along(pkgs), pkgs, f = function(i, pkg) {
#         tryCatch(
#           {
#             install_missing_pkgs(
#               pkg,
#               libpath = libpath,
#               prompt = paste0("[", i, "/", length(pkgs), "] Installing shinyverse package: "),
#               verbose = verbose
#             )
#           },
#           error = function(e) {
#             message("Failed to install ", pkg, " from universe")
#           }
#         )
#       })
#     }
#   )

# }

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

pak_deps_map <- new.env(parent = emptyenv())


get_extra_shinyverse_deps <- function(packages) {
  if (length(packages) == 0) return(NULL)

  # Recursively find all shinycoreci packages as dependencies from `packages`
  ret <- c()
  queue <- packages
  while (TRUE) {
    pkg <- queue[1]
    queue <- queue[-1]

    if (is.null(pkg)) break
    if (is.na(pkg) && length(queue) == 0) break
    if (is.na(pkg)) next
    if (pkg %in% ret) next

    pkg_dep_packages <- pak_deps_map[[pkg]]
    if (is.null(pkg_dep_packages)) {
      withr::with_options(
        list(
          repos = shinyverse_repos_option()
        ),
        {
          stopifnot(utils::packageVersion("pak") >= "0.3.0")
          pak__pkg_deps <- utils::getFromNamespace("pkg_deps", "pak")
          pkg_dep_packages <- pak__pkg_deps(pkg)$package
          # str(list(pkg = pkg, pkg_dep_packages = pkg_dep_packages))
        }
      )
      # Store in env does not need `<<-`
      pak_deps_map[[pkg]] <- pkg_dep_packages
    }

    queue <- unique(c(
      queue,
      pkg_dep_packages[pkg_dep_packages %in% shinyverse_pkgs]
    ))

    if (pkg %in% shinyverse_pkgs) {
      ret <- c(ret, pkg)
    }
  }

  ret
}


# packages is what is really installed given the value of packages
install_missing_pkgs <- function(
  packages,
  ...,
  libpath = .libPaths()[1],
  upgrade = FALSE,
  dependencies = NA,
  prompt = "Installing packages: ",
  verbose = TRUE
) {
  stopifnot(length(list(...)) == 0)

  # Make sure to get underlying dependencies
  # Always add shiny as it is always needed
  # Only install shinycoreci if the libpath is shinycoreci_libpath()
  packages <- unique(c(
    packages,
    get_extra_shinyverse_deps(packages)
  ))

  pkgs_to_install <- packages[!(packages %in% names(installed_pkgs))]

  if (length(pkgs_to_install) > 0) {
    message(
      prompt,
      paste0(pkgs_to_install, collapse = ", ")
    )
    message("libpath: ", libpath)

    if (
      "shinycoreci" %in% pkgs_to_install && libpath == shinycoreci_libpath()
    ) {
      # Install shinycoreci from the universe, but with no dependencies
      install_pkgs_with_callr(
        "shinycoreci",
        libpath = libpath,
        upgrade = upgrade,
        dependencies = FALSE,
        verbose = verbose
      )
      # Update the installed status as an install error was not thrown
      installed_pkgs[["shinycoreci"]] <- TRUE
      pkgs_to_install <- pkgs_to_install[pkgs_to_install != "shinycoreci"]
    }

    if (length(pkgs_to_install) > 0) {
      install_pkgs_with_callr(
        pkgs_to_install,
        libpath = libpath,
        upgrade = upgrade,
        dependencies = dependencies,
        verbose = verbose
      )
    }
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
    function(repos_option, packages, upgrade, dependencies) {
      options(repos = repos_option)

      # Performing a leap of faith that pak is installed.
      # Avoids weird installs when using pak to install shinycoreci
      stopifnot(utils::packageVersion("pak") >= "0.3.0")
      pak__pkg_install <- utils::getFromNamespace("pkg_install", "pak")
      message(
        "Installing packages with pak::pkg_install(): ",
        paste0(packages, collapse = ", ")
      )
      pak__pkg_install(
        packages,
        ask = FALSE, # Not interactive, so don't ask
        upgrade = upgrade,
        dependencies = dependencies
      )
    },
    list(
      repos_option = shinyverse_repos_option(),
      packages = packages,
      upgrade = upgrade,
      dependencies = dependencies
    ),
    show = TRUE,
    libpath = libpath,
    supervise = TRUE,
    spinner = TRUE # helps with CI from timing out
  )
}

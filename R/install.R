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
  c(
    # Use the shinycoreci universe to avoid GH rate limits!
    "AAA" = shinyverse_cran_url,
    getOption("repos", c("CRAN" = "https://cloud.r-project.org"))
  )
}

# Packages removed from CRAN that need to be installed from alternative sources.
# Map from CRAN package name to pak-compatible reference (e.g. GitHub owner/repo).
cran_archived_pkgs <- c(
  "plogr" = "krlmlr/plogr",
  "pryr" = "hadley/pryr"
)

# Use alternative package refs for packages whose r-universe source archives
# are currently unstable on older macOS R releases.
macos_oldrel_pkg_refs <- function(platform_val = platform(), r_version = getRversion()) {
  if (
    identical(platform_val, "mac") &&
      utils::compareVersion(as.character(r_version), "4.3.0") < 0
  ) {
    return(c(
      "bsicons" = "rstudio/bsicons",
      "crosstalk" = "rstudio/crosstalk",
      "htmltools" = "cran::htmltools",
      "later" = "cran::later",
      "shinyjster" = "schloerke/shinyjster"
    ))
  }

  character()
}

# Remap any packages to alternative pak references when needed.
remap_pkg_refs <- function(packages, platform_val = platform(), r_version = getRversion()) {
  pkg_ref_overrides <- c(
    cran_archived_pkgs,
    macos_oldrel_pkg_refs(platform_val, r_version)
  )

  idx <- match(packages, names(pkg_ref_overrides))
  remapped <- !is.na(idx)
  if (any(remapped)) {
    message(
      "Remapping package refs: ",
      paste0(packages[remapped], " -> ", pkg_ref_overrides[idx[remapped]], collapse = ", ")
    )
    packages[remapped] <- pkg_ref_overrides[idx[remapped]]
  }
  packages
}

# Backward-compatible wrapper for older call sites.
remap_archived_pkgs <- function(packages) {
  remap_pkg_refs(packages)
}


install_macos_oldrel_pinned_pkgs <- function(
  packages,
  ...,
  libpath = .libPaths()[1],
  upgrade = FALSE,
  dependencies = NA,
  verbose = TRUE,
  platform_val = platform(),
  r_version = getRversion()
) {
  stopifnot(length(list(...)) == 0)

  pkg_ref_overrides <- macos_oldrel_pkg_refs(platform_val, r_version)
  pinned_pkgs <- intersect(packages, names(pkg_ref_overrides))

  if (length(pinned_pkgs) == 0) {
    return(packages)
  }

  install_pkgs_with_callr(
    unname(pkg_ref_overrides[pinned_pkgs]),
    libpath = libpath,
    upgrade = upgrade,
    dependencies = dependencies,
    verbose = verbose
  )

  for (package in pinned_pkgs) {
    installed_pkgs[[package]] <- TRUE
  }

  packages[!(packages %in% pinned_pkgs)]
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
  if (length(packages) == 0) {
    return(NULL)
  }

  # Recursively find all shinycoreci packages as dependencies from `packages`
  ret <- c()
  queue <- packages
  while (TRUE) {
    pkg <- queue[1]
    queue <- queue[-1]

    if (is.null(pkg)) {
      break
    }
    if (is.na(pkg) && length(queue) == 0) {
      break
    }
    if (is.na(pkg)) {
      next
    }
    if (pkg %in% ret) {
      next
    }

    pkg_dep_packages <- pak_deps_map[[pkg]]
    if (is.null(pkg_dep_packages)) {
      # Install pak if not already installed
      if (!requireNamespace("pak", quietly = TRUE)) {
        install.packages("pak")
      }

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

  pkgs_to_install <- packages[
    !(packages %in% names(installed_pkgs)) &
      !vapply(packages, is_installed, logical(1), libpath = libpath)
  ]

  if (length(pkgs_to_install) > 0) {
    message(
      prompt,
      paste0(pkgs_to_install, collapse = ", ")
    )
    message("libpath: ", libpath)

    pkgs_to_install <- install_macos_oldrel_pinned_pkgs(
      pkgs_to_install,
      libpath = libpath,
      upgrade = upgrade,
      dependencies = dependencies,
      verbose = verbose
    )

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
        remap_pkg_refs(pkgs_to_install),
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

      # Install pak if not already installed
      if (!requireNamespace("pak", quietly = TRUE)) {
        install.packages("pak")
      }

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

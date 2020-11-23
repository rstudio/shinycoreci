

#' Install direct \pkg{shinycoreci} dependencies
#'
#' If something goes wrong, default to installing `shinycoreci` from GitHub. Then try installing the dependencies again. See the examples.
#'
#' @inheritParams test_shinyjster
#' @param try_again Logical to determine if RStudio IDE should try again after a failure
#' @param assert Logical to determine if an error should be thrown or RStudio should be restarted
#' @export
#' @examples
#' \dontrun{remotes::install_github("rstudio/shinycoreci")
#' shinycoreci::install_exact_shinycoreci_deps("apps")}
install_exact_shinycoreci_deps <- function(dir = "apps", apps = apps_runtests(dir), try_again = TRUE, assert =  interactive()) {

  missing_dir <- missing(dir)
  missing_apps <- missing(apps)

  installed_something <- FALSE

  # Make sure shinycoreci is up to date
  message("Update shinycoreci...", appendLF = FALSE)
  shinycoreci_info <- remotes::package_deps("shinycoreci")
  if (shinycoreci_info$diff < 0) {
    installed_something <- TRUE
    message("") # closs off line
    # update package
    remotes__update_package_deps(shinycoreci_info, upgrade = TRUE)
    # Make sure Suggest'ed dependencies are installed
    remotes::install_deps(system.file(package = "shinycoreci"), dependencies = TRUE, upgrade = TRUE)

  } else {
    message(" OK")
  }

  # all remotes based from shinycoreci
  message("Gathering recursive remotes...", appendLF = FALSE)
  scci_remotes_all <- cached_remotes_order()$remotes_to_install
  message(" OK")
  scci_remotes <- unique(unname(unlist(scci_remotes_all)))

  message("Gathering dependency information...", appendLF = FALSE)
  # include shinycoreci to get shinycoreci deps installed
  scci_app_deps <- app_deps(dir, apps = apps, include_shinycoreci = TRUE)
  message(" OK")

  # determine apps to check
  should_be_cran_only <- setdiff(scci_app_deps$package, c("shinycoreci", scci_remotes))
  should_be_github_only <- scci_remotes

  # check cran pkgs
  message("Checking all non-Remote packages are CRAN packages...", appendLF = FALSE)
  cran_info <- scci_app_deps[scci_app_deps$package %in% should_be_cran_only, ]
  # get packages that are currently not cran sources or are behind in version
  should_install_cran <- (!cran_info$is_cran) | (cran_info$diff < 0)
  if (any(should_install_cran)) {
    installed_something <- TRUE
    to_install <- cran_info$package[should_install_cran]
    message("") # close off line
    message("Installing CRAN pkgs: ", paste0("'", to_install, "'", collapse = ", "))
    # make sure the old package is gone!
    install_cran_packages_safely(to_install)
  } else {
    message(" OK")
  }

  message("Checking all Remotes are installed from GitHub...", appendLF = FALSE)
  remotes_info <- scci_app_deps[scci_app_deps$package %in% should_be_github_only, ]
  # check if packages are installed from github or are behind
  if (any(remotes_info$is_cran)) {
    message("") # close off line
    installed_something <- TRUE
    message("Re-installing some packages as these Remotes were not installed from GitHub")
    print(tibble::as_tibble(remotes_info[remotes_info$is_cran, ]))

    currently_cran_needs_github_pkgs <- remotes_info$package[remotes_info$is_cran]

    remote_to_pkgs <- cached_remotes_order()$remote_needs_all_pkgs
    # for every remote that shinycoreci needs installed...
    mapply(
      names(remote_to_pkgs),
      unname(remote_to_pkgs),
      FUN = function(remote_chr, remote_pkg_names) {
        # return early if it's direct remote dependencies do not need to be converted from a CRAN to GitHub package
        if (!any(currently_cran_needs_github_pkgs %in% remote_pkg_names)) {
          return()
        }
        pkg_name <- cached_remotes_order()$remote_to_pkg[[remote_chr]]
        # get the remote of the currently installed github package
        remote <- scci_app_deps$remote[scci_app_deps$package == pkg_name][[1]]
        # reinstall it to bring in all missing dependencies
        remotes::install_github(repo_from_remote(remote), force = TRUE, upgrade = TRUE)

        NULL # return nothing
      }
    )
  } else {
    message(" OK")
  }

  message("Checking GitHub packages are up to date...", appendLF = FALSE)
  should_update_github <- (remotes_info$diff < 0) & (!remotes_info$is_cran)
  if (any(should_update_github)) {
    message("") # close off line
    installed_something <- TRUE
    message("Updating GitHub packages:")
    print(tibble::as_tibble(remotes_info[should_update_github, ]))
    remotes__update_package_deps(remotes_info[should_update_github, ], upgrade = TRUE)
  } else {
    message(" OK")
  }

  if (installed_something) {
    if (isTRUE(assert)) {
      if (isTRUE(try_again) && rstudioapi::isAvailable()) {
        func <- paste0(
          "shinycoreci::install_exact_shinycoreci_deps(",
          paste0(collapse = ", ",
            c(
              if (!missing_dir) fn_arg("dir", dir),
              if (!missing_apps) fn_arg("apps", apps),
              fn_arg("try_again", FALSE)
            )
          ),
          ")"
        )
        message("Restarting RStudio to try again in a fresh session")
        message("Note: This next function call should pass!!")
        rstudioapi::restartSession(func)
        return(invisible(FALSE))
      }

      func <- paste0("shinycoreci::install_exact_shinycoreci_deps(\"", dir, "\")")
      stop(
        "Some packages were overwritten. Please restart your R session and run this function again.",
        "\n\n\t", func, "\n\n",
        call. = FALSE
      )
    } else {
      # assert = FALSE, installed_something = TRUE
      message("Some packages were overwritten. You may need to restart your R session for them to take effect.")
    }
  } else {
    message("Session is up to date!")
  }

  invisible(TRUE)
}


repo_from_remote <- function(remote_obj) {
  if (!inherits(remote_obj, "github_remote")) {
    utils::str(remote_obj)
    stop("not a remote!")
  }
  paste0(
    remote_obj$username,
    "/",
    remote_obj$repo,
    "@",
    remote_obj$branch %||% "master"
  )
}



# Gather all names of packages that should be installed by github
cached_remotes_order <- local({
  cache_val <- NULL

  function() {
    if (!is.null(cache_val)) {
      return(cache_val)
    }

    cache_val <<- validate_remotes_order()
    cache_val
  }
})



# used in shinycoreci-apps
install_ci <- function(upgrade = TRUE, dependencies = NA, credentials = remotes::git_credentials()) {
  # https://github.com/rstudio/shinytest/archive/rc-v1.4.0.tar.gz

  remotes_pkgs <- split_remotes(
    remotes__load_pkg_description(system.file(package = "shinycoreci"))$remotes
  )
  pkgs_installed <- lapply(remotes_pkgs, function(remotes_pkg) {
    repo_spec <- remotes::parse_github_repo_spec(remotes_pkg)

    if (nchar(repo_spec$pull) > 0) {
      stop("Can not install a pull request. Use a direct branch name or sha")
    }
    if (nchar(repo_spec$release) > 0) {
      stop("Can not install a release. Use a direct branch time or sha")
    }
    if (nchar(repo_spec$ref) == 0) {
      repo_spec$ref <- "master"
    }

    # install_git("git://github.com/hadley/stringr.git", ref = "stringr-0.2")
    cat("Installing git:", repo_spec$username, "/", repo_spec$repo, "@", repo_spec$ref, "\n", sep = "")
    remotes::install_git(
      url = paste0("git://github.com/", repo_spec$username, "/", repo_spec$repo, ".git"),
      ref = repo_spec$ref,
      upgrade = upgrade,
      dependencies = dependencies,
      credentials = credentials
    )
  })

  # install remaining suggested packages
  to_install <- setdiff(suggested_pkgs()$Package, unlist(pkgs_installed))
  for (pkg in to_install) {
    if (!is_installed(pkg)) {
      was_installed <- install_binary_or_source(pkg)
      if (!was_installed) {
        stop("Could not install suggested package: ", pkg)
      }
    }
  }

  invisible()
}



# Used in CI testing
validate_remotes_order <- function() {

  remotes__github_remote <- triple_colon("remotes", "github_remote")

  ## Map from github ref to package name
  # USER/REPO@REF: PKG
  remote_to_pkg <- list()

  # USER/REPO@REF: [USER/REPO@REF]
  remote_needs_remotes <- list()

  base_remotes <- split_remotes(
    remotes__load_pkg_description(system.file(package = "shinycoreci"))$remotes
  )

  i <- 1
  # init with 'rstudio/shinycoreci'
  remotes_to_inspect <- base_remotes
  while (i <= length(remotes_to_inspect)) {
    remotes_pkg <- remotes_to_inspect[i]
    i <- i + 1 # increment early; do not use value in loop

    # don't recurse forever
    if (!is.null(remote_needs_remotes[[remotes_pkg]])) {
      next
    }
    cat("inspecting: ", remotes_pkg, "\n", sep = "")

    # get remote info
    github_remote <- remotes__github_remote(repo = remotes_pkg)

    # use raw file url to avoid using GitHub API
    # get DESCRIPTION file from github
    # https://raw.githubusercontent.com/rstudio/shiny/master/DESCRIPTION
    desc_url <- paste0(
      "https://raw.githubusercontent.com",
      "/", github_remote$username,
      "/", github_remote$repo,
      "/", github_remote$ref,
      if (!is.null(github_remote$subdir)) paste0("/", github_remote$subdir),
      "/DESCRIPTION"
    )
    desc_content <- readLines(desc_url)
    if (length(desc_content) < 10) {
      stop("DESCRIPTION file not found for ", remotes_pkg)
    }
    # get desc contents
    desc <- local({
      tmp <- tempfile()
      on.exit(unlink(tmp))
      writeLines(desc_content, tmp)
      as.list(read.dcf(tmp)[1,])
    })

    # get package name
    pkg_name <- desc$Package
    # save ref to pkg name
    remote_to_pkg[[remotes_pkg]] <- pkg_name

    # get current pkg's remotes
    desc_remotes <- if (is.null(desc$Remotes)) character(0) else split_remotes(desc$Remotes)

    # append to end to keep looking at remotes
    remotes_to_inspect <- c(remotes_to_inspect, desc_remotes)
    remote_needs_remotes[[remotes_pkg]] <- desc_remotes
  }

  # all remote information has been gathered by this point

  ## map to track what packages have been seen
  # PKG: TRUE
  pkgs_seen <- list()
  remote_needs_all_remotes <- list()
  remote_needs_all_pkgs <- list()

  # See if `base_remotes` are in a valid order
  # for each base remote value...
  for (remote_val in base_remotes) {

    # gather all remotes needed recursively while trying to avoid infinite recursion
    remotes_needed <- list()
    remotes_to_look_at <- remote_val
    jj <- 1
    while (jj <= length(remotes_to_look_at)) {
      remote_to_look_at <- remotes_to_look_at[jj]
      jj <- jj + 1
      if (!is.null(remotes_needed[[remote_to_look_at]])) {
        next
      }
      needed <- remote_needs_remotes[[remote_to_look_at]]
      # store needed remotes
      remotes_needed[[remote_to_look_at]] <- needed
      # look at more remotes
      remotes_to_look_at <- c(remotes_to_look_at, needed)
    }
    # get vector of all remotes needed for `remote_val`
    remotes_needed_set <- unname(unlist(remotes_needed))
    # store all remotes needed for `remote_val`
    remote_needs_all_remotes[[remote_val]] <- remotes_needed_set

    # get the needed remotes package name
    pkgs_needed <- vapply(remotes_needed_set, function(rn) remote_to_pkg[[rn]], character(1), USE.NAMES = FALSE)
    remote_needs_all_pkgs[[remote_val]] <- pkgs_needed

    # if the `base_pkg` has already seen one of these remotes, then report the bad package name
    if (any(pkgs_needed %in% names(pkgs_seen))) {
      bad_remotes <- remotes_needed_set[pkgs_needed %in% names(pkgs_seen)]
      bad_pkgs <- vapply(bad_remotes, function(rn) remote_to_pkg[[rn]], character(1), USE.NAMES = FALSE)

      utils::str(remote_needs_remotes)
      stop(
        "`", remote_val, "` needs `", dput_arg(bad_remotes), "`.\n",
        "Move `", dput_arg(bad_pkgs), "` lower than `", remote_val, "` in the `Remotes: ` order in the `shincoreci` `./DESCRIPTION` file.\n",
        "This will insure the proper package version installed using `remotes::install_github()`"
      )
    }

    # mark pkg as seen
    pkg_val <- remote_to_pkg[[remote_val]]
    pkgs_seen[[pkg_val]] <- TRUE
  }

  list(
    remote_to_pkg = remote_to_pkg,
    remote_needs_remotes = remote_needs_remotes,
    remote_needs_all_remotes = remote_needs_all_remotes,
    remote_needs_all_pkgs = remote_needs_all_pkgs,
    remotes_to_install = sort(unique(unname(unlist(remote_to_pkg))))
  )
}

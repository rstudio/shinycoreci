#' Deploy apps to a server
#'
#' Run this in the terminal (not RStudio IDE) as it has issues when installing some packages.
#'
#' @param dir A base folder containing all applications to be deployed
#' @param apps A character vector of fully defined shiny application folders
#' @param account,server args supplied to `[rsconnect::deployApp]`
#' @param cores number of cores to use when deploying
#' @param update_pkgs A logical value indicating if a check should be made to update all installed packages
#' @param retry If \code{TRUE}, try failure apps again. (Only happens once.)
#' @export
deploy_apps <- function(
  dir = "apps",
  apps = basename(apps_deploy(dir)),
  account = "testing-apps",
  server = "shinyapps.io",
  cores = 1,
  update_pkgs = c("all", "shinycoreci", "installed", "none"),
  retry = TRUE
) {

  is_missing <- list(
    account = missing(account),
    server = missing(server),
    apps = missing(apps),
    cores = missing(cores)
  )

  cores <- validate_cores(cores)
  validate_rsconnect_account(account, server)
  update_packages_installed(dir, update_pkgs = update_pkgs)

  # Use a new R process just in case there were some packages updated
  # this avoids any odd "currently loaded" namespace issue
  original_dir <- dir
  original_apps <- apps
  apps_dirs <- if (identical(dir, "")) apps else file.path(dir, apps)
  deploy_res <- callr::r(
    show = TRUE,
    spinner = TRUE, # helps with CI from timing out
    args = list(
      apps_dirs = apps_dirs,
      cores = cores,
      account = account,
      server = server
    ),
    function(apps_dirs, cores, account, server) {
      pb <- progress::progress_bar$new(
        total = ceiling(length(apps_dirs) / cores),
        format = "\n\n:name [:bar] :current/:total eta::eta elapsed::elapsed\n",
        show_after = 0,
        clear = FALSE,
        force = TRUE
      )
      deploy_apps_ <- function(app_dir) {
        pb$tick(tokens = list(name = basename(app_dir)))
        deployment_worked <- try({
          rsconnect::deployApp(
            appDir = app_dir,
            appName = basename(app_dir),
            account = account,
            server = server,
            # logLevel = 'verbose',
            # do not launch browser
            launch.browser = FALSE,
            # force the app to update
            forceUpdate = TRUE,
            # do not lint the app (ex: 171 has "relative" file path)
            lint = FALSE
          )
        })
        if (inherits(deployment_worked, 'try-error')) {
          return(1)
        } else {
          return(as.numeric(!deployment_worked))
        }
      }

      deploy_res <-
        if (cores > 1) {
          parallel::mclapply(apps_dirs, deploy_apps_, mc.cores = cores)
        } else {
          lapply(apps_dirs, deploy_apps_)
        }
      deploy_res <- unlist(deploy_res)
      pb$terminate() # make sure it goes away

      deploy_warnings <- warnings()
      if (length(deploy_warnings) != 0) {
        cat("\n")
        print(deploy_warnings)
      }

      deploy_res
    }
  )

  if (all(deploy_res == 0)) {
    # success!
    message("No errors found when deploying apps")
    return(invisible(NULL))
  }

  # something failed... make a "retry failed apps" func call
  dput_arg <- function(x) {
    f <- file()
    on.exit({
      close(f)
    })
    dput(x, f)
    ret <- paste0(readLines(f), collapse = "\n")
    ret
  }
  error_apps <- original_apps[deploy_res != 0]
  args <- c(
    "dir = ", dput_arg(original_dir),
    paste0("apps = ", dput_arg(error_apps)),
    if (!is_missing$account) paste0("account = ", dput_arg(account)),
    if (!is_missing$server) paste0("server = ", dput_arg(server)),
    "cores = 1",
    "update_pkgs = \"none\"",
    "retry = FALSE"
  )
  fn <- paste0(
    "deploy_apps(", paste0(args, collapse = ", "),")"
  )

  if (isTRUE(retry)) {
    message("Retrying to deploy problem apps.  Calling:\n", fn)
    return(
      deploy_apps(
        dir = original_dir,
        apps = error_apps,
        account = account,
        server = server,
        cores = 1,            # simplify it
        update_pkgs = "none", # no need to update again, still in the original function exec
        retry = FALSE         # do not allow for infinite retries
      )
    )
  }

  # do not retry... throw error
  stop(
    "\nError deploying apps. To re-deploy:\n",
    fn,
    "\n"
  )

}


validate_rsconnect_account <- function(account, server) {
  accts <- rsconnect::accounts()
  accts_found <- sum(
    (account %in% accts$name) &
    (server %in% accts$server)
  )
  if (accts_found == 0) {
    print(accts)
    stop("please set an account with `rsconnect::setAccountInfo()` to match directly to `rsconnect::accounts()` information")
  } else if (accts_found > 1) {
    print(accts)
    stop("more than one account matches `rsconnect::accounts()`. Fix it?")
  }
  invisible(rsconnect::accountInfo(account, server))
}


update_packages_installed <- function(dir, update_pkgs = c("all", "shinycoreci", "installed", "none")) {
  update_pkgs <- match.arg(update_pkgs, several.ok = TRUE)
  if ("all" %in% update_pkgs) {
    update_pkgs <- c("shinycoreci", "installed")
  } else if ("none" %in% update_pkgs) {
    update_pkgs <- "none"
  }

  # TODO pull in app_deps!
  if ("shinycoreci" %in% update_pkgs) {
    message("Update shinycoreci and app dependencies")
    shinycoreci_deps <- app_deps(dir)

    needs_update <- as.logical(shinycoreci_deps$diff)
    if (any(needs_update)) {
      # make sure these packages are installed!
      update_package_deps <- utils::getFromNamespace("update.package_deps", "remotes")
      update_package_deps(shinycoreci_deps, upgrade = "always")
    }
  }

  if ("installed" %in% update_pkgs) {
    # update all packages! (this could involve unnecessary packages being updated)
    message("Update installed dependencies")
    remotes::update_packages(packages = TRUE, upgrade = "default")
  }

}


validate_cores <- function(cores) {
  cores <- as.numeric(cores)
  if (is.na(cores)) {
    stop("number of cores should be a numeric value")
  }
  cores
}

#' Deploy apps to a server
#'
#' Run this in the terminal (not RStudio IDE) as it has issues when installing some packages.
#'
#' Installation will use default libpaths.
#'
#' @param apps A character vector of fully defined shiny application folders
#' @param account,server args supplied to `[rsconnect::deployApp]`
#' @param ... ignored
#' @param extra_packages A character vector of extra packages to install
#' @param cores number of cores to use when deploying
#' @param retry If \code{TRUE}, try failure apps again. (Only happens once.)
#' @param retrying_ For internal use only
#' @inheritParams resolve_libpath
#' @export
deploy_apps <- function(
  apps = apps_deploy,
  account = "testing-apps",
  server = "shinyapps.io",
  ...,
  local_pkgs = FALSE,
  extra_packages = NULL,
  cores = 1,
  retry = 2,
  retrying_ = FALSE
) {
  is_missing <- list(
    account = missing(account),
    server = missing(server),
    apps = missing(apps),
    cores = missing(cores)
  )

  apps <- resolve_app_name(apps)

  libpath <- resolve_libpath(local_pkgs = local_pkgs)

  if (!retrying_) {
    # Always make sure the app dependencies are available
    install_missing_app_deps(apps, libpath = libpath)
  }

  cores <- validate_cores(cores)
  validate_rsconnect_account(account, server)

  message("\nDeploying apps!\n")

  # Use a new R process just in case there were some packages updated
  # this avoids any odd "currently loaded" namespace issue
  app_dirs <- vapply(apps, app_path, character(1))
  deploy_res <- callr::r(
    show = TRUE,
    spinner = TRUE, # helps with CI from timing out
    libpath = libpath, # use shinyverse library path
    args = list(
      apps_dirs = app_dirs,
      cores = cores,
      account = account,
      server = server,
      progress_bar = progress_bar,
      repos_option = shinyverse_repos_option()
    ),
    function(apps_dirs, cores, account, server, progress_bar, repos_option) {
      # Set the shinyverse repos option
      options(repos = repos_option)

      pb <- progress_bar(
        total = ceiling(length(apps_dirs) / cores),
        format = "\n\n:name [:bar] :current/:total eta::eta elapsed::elapsed\n"
      )
      deploy_apps_ <- function(app_dir) {
        pb$tick(tokens = list(name = basename(app_dir)))

        # Do not deploy `./tests/` files.
        # Prevents unnecessary images bloating size of deploy
        # Prevents need for `shinycoreci` in most apps
        app_files <- dir(app_dir, recursive = TRUE)
        app_files <- app_files[!grepl("^tests/", app_files)]

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
            lint = FALSE,
            appFiles = app_files
          )
        })
        if (inherits(deployment_worked, "try-error")) {
          # Debug manifest.json
          try({
            withr::with_tempdir({
              rsconnect::writeManifest(app_dir)
              cat(paste0(readLines(file.path(appDir, "manifest.json")), collapse = "\n"), "\n")
              unlink(file.path(appDir, "manifest.json"))
            })
          })
          return(1)
        } else {
          return(as.numeric(!isTRUE(deployment_worked)))
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

  if ((!any(deploy_res == 1)) && length(deploy_res) == length(app_dirs)) {
    # success!
    message("No errors found when deploying apps")
    return(invisible(NULL))
  }

  # something failed... make a "retry failed apps" func call
  error_apps <- apps[deploy_res != 0]
  args <- c(
    fn_arg("apps", error_apps),
    if (!is_missing$account) fn_arg("account", account),
    if (!is_missing$server) fn_arg("server", server),
    fn_arg("cores", 1),
    fn_arg("retrying_", TRUE),
    fn_arg("retry", retry - 1)
  )
  fn <- paste0(
    "deploy_apps(",
    paste0(args, collapse = ", "),
    ")"
  )

  if (is.numeric(retry) && length(retry) > 0 && retry > 0) {
    message("Retrying to deploy problem apps.  Calling:\n", fn)
    return(
      deploy_apps(
        apps = error_apps,
        account = account,
        server = server,
        cores = 1, # simplify it
        retrying_ = TRUE, # no need to update again, still in the original function exec
        retry = retry - 1 # do not allow for infinite retries
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
    stop(
      "please set an account with `rsconnect::setAccountInfo()` to match directly to `rsconnect::accounts()` information"
    )
  } else if (accts_found > 1) {
    print(accts)
    stop("more than one account matches `rsconnect::accounts()`. Fix it?")
  }
  invisible(rsconnect::accountInfo(account, server))
}


validate_cores <- function(cores) {
  cores <- as.numeric(cores)
  if (is.na(cores)) {
    stop("number of cores should be a numeric value")
  }
  cores
}

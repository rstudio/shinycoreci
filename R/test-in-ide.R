#' Test apps within RStudio IDE
#'
#' Automatically runs the next app in a fresh RStudio session after closing the current app. To stop,  send an interrupt signal (\verb{esc} or \verb{ctrl+c}) to the app twice in rapid succession.
#'
#' Kill testing by hitting \verb{esc} in RStudio.
#'
#' If \code{options()} need to be set, set them in your \preformatted{.Rprofile} file.  See \code{usethis::edit_r_profile()}
#'
#' @inheritParams test_in_browser
#' @param delay Time to wait between applications. \[`1`\]
#' @param viewer RStudio IDE viewer to use.  \[`"pane"`\]
#' @param refresh_ For internal use. If TRUE, packages will not be reinstalled.
#' @export
#' @examples
#' \dontrun{
#' test_in_ide(dir = "apps")
#' }
test_in_ide <- function(
    app_name = apps[1],
    apps = apps_manual,
    ...,
    port = 8000,
    host = "127.0.0.1",
    delay = 1,
    local_pkgs = FALSE,
    viewer = NULL,
    refresh_ = FALSE) {
  sys_call <- match.call()
  apps <- resolve_app_name(apps)

  should_install <- !isTRUE(local_pkgs)
  libpath <- resolve_libpath(local_pkgs = local_pkgs)
  withr::local_libpaths(libpath, action = "prefix")

  app_name <- resolve_app_name(app_name)

  if (should_install) {
    install_missing_app_deps(app_name, libpath = libpath)
  }

  if (rstudioapi::isAvailable()) {
    # stop("This function should only be run within the RStudio IDE")

    if (rstudioapi::isAvailable("1.3.387")) {
      # window, pane, browser
      if (missing(viewer)) {
        # this should be the default value for `viewer` once IDEv1.2 is not supported
        viewer <- rstudioapi::readRStudioPreference("shiny_viewer_type", "pane")
      }
      shiny_viewer_type <- force(viewer)
      on.exit(
        {
          rstudioapi::writeRStudioPreference("shiny_viewer_type", shiny_viewer_type)
        },
        add = TRUE
      )

      if (is.null(viewer)) {
        message("!! Setting `shiny_viewer_type` to `'pane'` !!")
        viewer <- "pane"
      }
      # shiny viewer is not `window` or `pane`
      if (!is.null(viewer)) {
        viewer <- match.arg(viewer, c("pane", "window"), several.ok = FALSE)
      }
      # viewer supplied
      rstudioapi::writeRStudioPreference("shiny_viewer_type", viewer)
    } else {
      # RStudio, but early version
      # This feels hacky, but is necessary
      # This code should mirror the code above

      # shiny viewer is not `window` or `pane`
      if (is.null(viewer)) {
        message("!! Setting `shiny_viewer_type` to `'pane'` !!")
        viewer <- "pane"
      }
      try({
        runPane <- get(".rs.invokeShinyPaneViewer", envir = as.environment("tools:rstudio"))
        runWindow <- get(".rs.invokeShinyWindowViewer", envir = as.environment("tools:rstudio"))
        runFn <- switch(match.arg(viewer, c("pane", "window")),
          "pane" = runPane,
          "window" = runWindow
        )
        old_option <- options(shiny.launch.browser = runFn)
        on.exit({
          options(old_option)
        })
      })
    }
  }

  # # make sure the apps are ok to run
  # if (isTRUE(verify)) {
  #   app_status_verify(dir)
  # }
  # app_status_init(dir, user_agent = app_status_user_agent_ide())

  old_ops <- options(width = 100)
  on.exit(
    {
      options(old_ops)
    },
    add = TRUE
  )

  increment_app_and_wait <- function() {
    next_app_name <- next_app_name(app_name)

    restart_with_app(next_app_name)
  }

  restart_with_app <- function(app_name) {
    if (is.null(app_name)) {
      message("All done testing!")
      return(invisible(NULL))
    }

    # do not try to update apps again. Set the next app. Keep all existing arguments.
    next_sys_call_list <- as.list(sys_call)
    next_sys_call_list[[1]] <- substitute(shinycoreci::test_in_ide)
    next_sys_call_list$app_name <- app_name
    next_sys_call_list$refresh_ <- TRUE
    next_sys_call <- as.call(next_sys_call_list)

    message("Restarting RStudio and launching next app in ", delay, " second... (interrupt again to stop)")
    Sys.sleep(delay)
    message("Restarting RStudio with next app!")

    # # if this section of code is reached, it is considered a pass!
    # app_status_save(
    #   app_dir = file.path(dir, app),
    #   pass = TRUE,
    #   log = "(unknown; can not capture)",
    #   user_agent = app_status_user_agent_ide()
    # )
    next_sys_call_txt <- format(next_sys_call)
    if (shinycoreci_is_loaded_with_devtools()) {
      # dev mode
      next_sys_call_txt <- sub("shinycoreci::test_in_ide", "pkgload::load_all(); test_in_ide", next_sys_call_txt)
    }

    if (rstudioapi::isAvailable()) {
      # restart RStudio, run the next app
      rstudioapi::restartSession(next_sys_call_txt)
    } else {
      # if not in RStudio, run in the next tick...
      later::later(function() {
        eval(parse(text = next_sys_call_txt))
      })
    }
    return(invisible(app_name))
  }

  # If not in a fresh session, restart!
  if (!isTRUE(refresh_)) {
    restart_with_app(app_name)
    return()
  }


  message("Running ", app_name)
  tryCatch(
    {
      run_app(app_name, port = port, host = host)
    },
    error = function(e) {
      utils::alarm()
      message("")
      message("!! Error launching ", app_name, " !! Error: \n", e)
      message("")

      ans <- utils::menu(
        choices = c("yes", "no"),
        title = "Please mark the error above.\n\nContinue testing?"
      )

      if (ans == 2) {
        stop("...stopping testing...")
      }

      increment_app_and_wait()
    },
    interrupt = function(cond) {
      increment_app_and_wait()
    }
  )
}

ide_open_app <- function(app_name) {
  app_name <- resolve_app_name(app_name)
  owd <- setwd(app_path(app_name))
  cli::cli_alert("Opening app {.field {app_name}}")
  cli::cli_alert_info("App location: {.path {app_path(app_name)}}")

  app_files <- dir(pattern = "(app|ui).[Rr]")
  server_files <- dir(pattern = "server.[Rr]")
  test_files <- dir("tests/testthat", pattern = "test-", full.names = TRUE)

  files <- vapply(
    c(app_files, server_files, test_files),
    function(x) sprintf("{.path %s}", x),
    character(1)
  )

  cli::cli_h3("Test app files")
  cli::cli_ol(files)

  invisible(owd)
}



pad_left <- function(x, y, n) {
  x <- as.character(x)
  vapply(x, function(xi) {
    while (nchar(xi) < n) {
      xi <- paste0(y, xi)
    }
    xi
  }, character(1))
}
app_num <- function(x) {
  pad_left(x, "0", 3)
}


# has_multiple_apps <- function(dir, apps, app_name) {
#   get_app_num <- function(x) {
#     sub("^(\\d+)-.*$", "\\1", basename(x))
#   }
#   app_name <- normalize_app_name(dir, apps, app_name, increment = FALSE)

#   app_nums <- get_app_num(file.path(dir, apps))
#   duplicated_app_nums <- unique(app_nums[duplicated(app_nums)])

#   duplicated_app_nums <- setdiff(duplicated_app_nums, "015")

#   get_app_num(app_name) %in% duplicated_app_nums
# }

normalize_app_name <- function(
  apps,
  app_name,
  increment = FALSE
) {
  app_name_original <- app_name
  if (is.null(app_name) || identical(app_name, 0L)) {
    return(apps[1])
  }

  if (is.numeric(app_name)) {
    app_name <- app_num(app_name)
  }
  if (!(app_name %in% apps)) {
    matches <- grepl(app_name, apps)
    app_name <- apps[matches]
    if (length(app_name) > 1) {
      message("Found multiple apps.\n\tUsing the first app: ", app_name[1], ".\n\tFrom set: ", paste0(app_name, collapse = ", "))
      app_name <- app_name[1]
    }
  }
  app_pos <- which(basename(apps) == basename(app_name))
  if (length(app_pos) == 0) {
    stop("unknown app: ", app_name_original)
  }
  if (increment) {
    app_pos <- app_pos + 1
  }
  if (app_pos > length(apps)) {
    return(NULL)
  }
  apps[app_pos]
}


#' Test apps within RStudio IDE
#'
#' Automatically runs the next app in a fresh RStudio session after closing the current app. To stop,  send an interrupt signal (\verb{esc} or \verb{ctrl+c}) to the app twice in rapid succession.
#'
#' Kill testing by hitting \verb{esc} in RStudio.
#'
#' If \code{options()} need to be set, set them in your \preformatted{.Rprofile} file.  See \code{usethis::edit_r_profile()}
#'
#' @inheritParams test_shinyjster
#' @inheritParams test_in_browser
#' @param app app number or name to start with. If numeric, it will match the leading number in the testing application
#' @param delay Time to wait between applications. \[`1`\]
#' @param viewer RStudio IDE viewer to use.  \[`"pane"`\]
#' @export
#' @examples
#' \dontrun{test_in_ide(dir = "apps")}
test_in_ide <- function(
  dir = "apps",
  apps = apps_manual(dir),
  app = apps[1],
  port = 8000,
  host = "127.0.0.1",
  delay = 1,
  update_pkgs = TRUE,
  viewer = NULL,
  verify = TRUE
) {
  force(update_pkgs)
  validate_core_pkgs()

  # install all the packages
  if (isTRUE(update_pkgs)) {
    install_exact_shinycoreci_deps(dir, apps = apps, include_shinycoreci = TRUE)
  }

  sys_call <- match.call()

  if (rstudioapi::isAvailable()) {
    # stop("This function should only be run within the RStudio IDE")

    if (rstudioapi::isAvailable("1.3.387")) {
      # window, pane, browser
      if (missing(viewer)) {
        # this should be the default value for `viewer` once IDEv1.2 is not supported
        viewer <- rstudioapi::readRStudioPreference("shiny_viewer_type", "pane")
      }
      shiny_viewer_type <- force(viewer)
      on.exit({
        rstudioapi::writeRStudioPreference("shiny_viewer_type", shiny_viewer_type)
      }, add = TRUE)

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
      runPane <- get(".rs.invokeShinyPaneViewer", envir = as.environment("tools:rstudio"))
      runWindow <- get(".rs.invokeShinyWindowViewer", envir = as.environment("tools:rstudio"))
      runFn <- switch(
        match.arg(viewer, c("pane", "window")),
        "pane" = runPane,
        "window" = runWindow
      )
      old_option <- options(shiny.launch.browser = runFn)
      on.exit({
        options(old_option)
      })

    }
  }

  # make sure the apps are ok to run
  if (isTRUE(verify)) {
    app_status_verify(dir)
  }
  app_status_init(dir, user_agent = app_status_user_agent_ide())
  app_dirs <- file.path(dir, apps)

  old_ops <- options(width = 100)
  on.exit({
    options(old_ops)
  }, add = TRUE)

  app <- normalize_app_name(apps, app, increment = FALSE)
  increment_app_and_wait <- function() {

    next_app <- normalize_app_name(apps, app, increment = TRUE)

    if (is.null(next_app)) {
      message("All done testing!")
      return(invisible(NULL))
    }

    # do not try to update apps again. Set the next app. Keep all existing arguments.
    next_sys_call_list <- as.list(sys_call)
    next_sys_call_list[[1]] <- substitute(shinycoreci::test_in_ide)
    next_sys_call_list$app <- next_app
    next_sys_call_list$update_pkgs <- FALSE
    next_sys_call <- as.call(next_sys_call_list)

    message("Restarting RStudio and launching next app in ", delay, " second... (interrupt again to stop)")
    Sys.sleep(delay)

    # if this section of code is reached, it is considered a pass!
    app_status_save(
      app_dir = file.path(dir, app),
      pass = TRUE,
      log = "(unknown; can not capture)",
      user_agent = app_status_user_agent_ide()
    )
    next_sys_call_txt <- format(next_sys_call)
    is_loaded_with_devtools <- shinycoreci_is_loaded_with_devtools()
    if (is_loaded_with_devtools) {
      # dev mode
      next_sys_call_txt <- sub("shinycoreci::test_in_ide", "pkgload::load_all(); test_in_ide", next_sys_call_txt)
    }

    if (rstudioapi::isAvailable()) {
      # restart RStudio, run the next app
      rstudioapi::restartSession(next_sys_call_txt)
    } else {
      # if not in RStudio, run in the next tick...
      later::later(function() {
        eval(parse(text = next_sys_call))
      })
    }
    return(invisible(next_app))
  }


  message("Running ", app, " in ", dir)
  tryCatch(
    {
      run_app(file.path(dir, app), port = port, host = host)
    },
    error = function(e) {
      utils::alarm()
      message("")
      message("!! Error launching ", app, " !! Error: \n", e)
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

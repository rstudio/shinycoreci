
#' Test apps within the terminal
#'
#' Automatically runs the next app in a fresh callr::r_bg session.  To stop, close the shiny application window.
#'
#' @inheritParams test_shinyjster
#' @inheritParams shinyjster::run_jster_apps
#' @param port_background `port` for the background app process
#' @param app app number or name to start with. If numeric, it will match the leading number in the testing application
#' @param update_pkgs Logical that will try to automatically install packages. \[`TRUE`\]
#' @param verify Logical that will try to confirm shinycoreci-apps directory is the master branch
#' @export
#' @examples
#' \dontrun{test_in_browser(dir = "apps")}
test_in_browser <- function(
  dir = "apps",
  apps = apps_manual(dir),
  app = apps[1],
  port = 8080,
  port_background = NULL,
  host = "127.0.0.1",
  update_pkgs = TRUE,
  verify = TRUE
) {
  validate_core_pkgs()

  # install all the packages
  if (isTRUE(update_pkgs)) {
    install_exact_shinycoreci_deps(dir, apps = apps, include_shinycoreci = TRUE)
  }
  # make sure the apps are ok to run
  if (isTRUE(verify)) {
    app_status_verify(dir)
  }

  app_dirs <- file.path(dir, apps)
  app_infos <- lapply(app_dirs, function(app_dir) {
    app_proc <- NULL

    app_name <- basename(app_dir)

    port_background_val <- port_background

    output_lines_val <- ""
    output_lines_fn <- function(reset = FALSE) {
      if (is.null(app_proc)) {
        return(NULL)
      }
      if (isTRUE(reset)) {
        output_lines_val <<- ""
        return()
      }
      proc_output_lines <- app_proc$read_output_lines()
      if (any(nchar(proc_output_lines) > 0)) {
        output_lines_val <<- paste0(
          output_lines_val,
          if (nchar(output_lines_val) > 0) "\n",
          paste0(proc_output_lines, collapse = "\n")
        )
      }
      output_lines_val
    }

    stop_app <- function() {
      if (is.null(app_proc)) {
        return()
      }

      message("Killing background Shiny Session...", appendLF = FALSE)
      if (app_proc$is_alive()) {
        app_proc$kill()
      }
      message(" OK")
      # tell other funcs that app_proc is gone
      app_proc <<- NULL
    }

    list(
      app_name = app_name,
      user_agent = function(user_agent) {
        app_status_user_agent_browser(user_agent, "localhost")
      },
      start = function() {
        message("")
        message("Starting app: ", app_name)

        # kill prior app
        stop_app()

        if (is.null(port_background_val)) {
          port_background_val <<- httpuv::randomPort()
          message("Background port: ", port_background_val, "... OK")
        } else {
          port_is_available <- FALSE
          total_wait <- 2
          tries <- 20
          message("Testing background app port: ", port_background_val, "...", appendLF = FALSE)
          for (i in seq_len(tries)) {
            tryCatch(
              {
                s <- httpuv::startServer(host, port_background_val, list(), quiet = TRUE)
                s$stop()
                port_is_available <- TRUE
                break
              },
              error = function(e) {
                Sys.sleep(total_wait / tries)
                NULL
              }
            )
          }
          if (!port_is_available) {
            message("")
            stop("Port ", port_background_val, " was not available within ", total_wait, " seconds")
          }
          message(" OK")
        }


        # start new app
        message("Launching background app process...", appendLF = FALSE)
        app_proc <<- callr::r_bg(
          function(app_dir_, port_, host_, run_app_) {
            run_app_(
              app_dir_,
              port = port_,
              host = host_
            )
          },
          list(
            app_dir_ = app_dir,
            port_ = port_background_val,
            host_ = host,
            run_app_ = run_app
          ),
          supervise = TRUE,
          stdout = "|",
          stderr = "2>&1",
          cmdargs = c(
            "--slave", # tell the session that it's being controlled by something else
            # "-–interactive", # (UNIX only) # tell the session that it's interactive.... but it's not
            "--quiet", # no printing
            "--no-save", # don't save when done
            "--no-restore" # don't restore from .RData or .Rhistory
          )
        )
        message(" OK")

        # make sure the app is alive
        message("Making sure background app is alive...", appendLF = FALSE)
        total_wait <- 10
        interval <- 0.25
        httr::RETRY(
          "GET",
          paste0("http://", host, ":", port_background_val),
          pause_min = interval,
          pause_cap = interval,
          times = total_wait / interval,
          quiet = TRUE
        )
        message(" OK")

        TRUE
      },
      header = function() {
        shiny::tagList(shiny::tags$strong("App directory: "), shiny::tags$code(dir))
      },
      on_session_ended = stop_app,
      output_lines = output_lines_fn,
      app_url = function() {
        paste0("http://", host, ":", port_background_val, "/")
      }
    )
  })

  test_in_external(
    dir = dir,
    app_infos = app_infos,
    app = normalize_app_name(apps, app, increment = FALSE),
    host = host,
    port = port
  )
}

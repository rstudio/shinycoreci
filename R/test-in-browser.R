#' Test apps within the terminal
#'
#' Automatically runs the next app in a fresh callr::r_bg session.  To stop, close the shiny application window.
#'
#' @param app_name app number or name to start with. If numeric, it will match the leading number in the testing application
#' @param apps List of apps to test
#' @param port `port` for the foreground app process
#' @param port_background `port` for the background app process
#' @param host `host` for the foreground and background app processes
#' @param local_pkgs If `TRUE`, local packages will be used instead of the isolated shinyverse installation.
#' @param ... ignored
#' @export
#' @examples
#' \dontrun{test_in_browser()}
test_in_browser <- function(
  app_name = apps[1],
  apps = apps_manual,
  ...,
  port = 8080,
  port_background = NULL,
  host = "127.0.0.1",
  local_pkgs = FALSE
) {
  # libpath <- install_shinyverse(install = !isTRUE(local_pkgs))
  libpath <- shinyverse_libpath()

  app_infos <- lapply(apps, function(app_name) {
    app_proc <- NULL

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
      # user_agent = function(user_agent) {
      #   app_status_user_agent_browser(user_agent, "localhost")
      # },
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
          function(app_name_, port_, host_, run_app_, apps_folder_) {
            run_app_(
              app_name_,
              port = port_,
              host = host_,
              apps_folder = apps_folder_
            )
          },
          list(
            app_name_ = app_name,
            port_ = port_background_val,
            host_ = host,
            run_app_ = run_app,
            apps_folder_ = apps_folder
          ),
          libpath = libpath,
          supervise = TRUE,
          stdout = "|",
          stderr = "2>&1",
          cmdargs = c(
            "--slave", # tell the session that it's being controlled by something else
            # "--interactive", # (UNIX only) # tell the session that it's interactive.... but it's not
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
        shiny::tagList(shiny::tags$strong("App directory: "), shiny::tags$code(apps_folder))
      },
      on_session_ended = stop_app,
      output_lines = output_lines_fn,
      app_url = function() {
        paste0("http://", host, ":", port_background_val, "/")
      }
    )
  })

  test_in_external(
    app_infos = app_infos,
    default_app_name = resolve_app_name(app_name),
    host = host,
    port = port
  )

}

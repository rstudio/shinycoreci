
# TODO remove once test_ide is merged
normalize_app_name <- function(
  dir,
  apps,
  app_name,
  increment = FALSE
) {
  if (is.null(app_name) || identical(app_name, 0L)) {
    return(apps[1])
  }

  if (is.numeric(app_name)) {
    app_name <- app_num(app_name)
  }
  if (!(app_name %in% apps)) {
    app_name <- dir(dir, pattern = basename(app_name))
    if (length(app_name) > 1) {
      message("Found multiple apps.\n\tUsing the first app: ", app_name[1], ".\n\tFrom set: ", paste0(app_name, collapse = ", "))
      app_name <- app_name[1]
    }
  }
  app_pos <- which(basename(apps) == basename(app_name))
  if (length(app_pos) == 0) {
    stop("unknown app: ", app_name)
  }
  if (increment) {
    app_pos <- app_pos + 1
  }
  if (app_pos > length(apps)) {
    return(NULL)
  }
  file.path(dir, apps[app_pos])
}



#' Test apps within the terminal
#'
#' Automatically runs the next app in a fresh callr::r_bg session.  To stop, close the shiny application window.
#'
#' @inheritParams test_shinyjster
#' @param port_background `port` for the background app process
#' @param app app number or name to start with. If numeric, it will match the leading number in the testing application
#' @param update_pkgs Logical that will try to automatically install packages. \[`TRUE`\]
#' @export
#' @examples
#' \dontrun{test_in_browser(dir = "apps")}
test_in_browser <- function(
  dir = "apps",
  apps = basename(apps_manual(dir)),
  app = apps[1],
  port = 8080,
  port_background = 8001,
  host = "127.0.0.1",
  delay = 1,
  update_pkgs = TRUE
) {
  sys_call <- match.call()
  force(update_pkgs)

  if (rstudioapi::isAvailable()) {
    # browser, window, pane
    shiny_viewer_type <- rstudioapi::readRStudioPreference("shiny_viewer_type", "not-correct")
    if (!identical(shiny_viewer_type, "browser")) {
      on.exit({
        rstudioapi::writeRStudioPreference("shiny_viewer_type", shiny_viewer_type)
      }, add = TRUE)
      rstudioapi::writeRStudioPreference("shiny_viewer_type", "browser")
    }
  }

  app_dirs <- file.path(dir, apps)

  # install all the packages
  if (isTRUE(update_pkgs)) {
    install_exact_shinycoreci_deps(dir)
  }

  old_ops <- options(width = 100)
  on.exit({
    options(old_ops)
  }, add = TRUE)

  app <- normalize_app_name(dir, apps, app, increment = FALSE)

  panel_width <- "350px"

  ui <- shiny::fluidPage(
    shiny::fixedPanel(
      class = "server_panel",
      shiny::tags$div(
        class = "apps_dir",
        shiny::tags$strong("App directory: "), shiny::tags$code(dir)
      ),
      shiny::selectizeInput("app_name", NULL, apps, selected = app),
      shiny::tags$div(
        class = "button_container",
        shiny::actionButton("accept", "Accept!", class = "accept_button"),
        shiny::actionButton("refresh", "Refresh", class = "refresh_button"),
        shiny::actionButton("reject", "Reject", class = "reject_button"),
      ),
      shiny::verbatimTextOutput("server_output"),
    ),

    shiny::fixedPanel(
      class = "background_app",
      shiny::uiOutput("app_iframe", class = "iframe_container")
    ),

    shiny::tags$head(
      shiny::tags$style(paste0("
        .apps_dir {
          margin-bottom: 10px;
        }
        .server_panel {
          padding: 5px;
          top: 0;
          bottom: 0;
          left: 0;
          width: ", panel_width, ";
          height: 100vh;
          border-right-style: solid;
          border-right-color: #f0f0f0;
        }
        .background_app {
          top: 0;
          bottom: 0;
          left: ", panel_width, ";
          right: 0;
          height: 100vh;
        }

        .button_container {
          display: flex;
          flex-direction: row;
          align-items: stretch;
          align-content: stretch;
          justify-content: space-evenly;
          margin-bottom: 10px;
        }
        .button_container .btn {
          flex: 0 0 auto;
        }
        .button_container .accept_button:hover {
          background-color: rgb(172, 219, 180);
        }
        .button_container .accept_button {
          border-color: rgb(5, 164, 53);
        }
        .button_container .reject_button:hover {
          background-color: rgb(255, 182, 182);
        }
        .button_container .reject_button {
          border-color: rgb(228, 117, 117);
        }

        .iframe_container {
          display: flex;
          flex-direction: column;
          align-items: stretch;
          align-content: stretch;
          height: 100vh;
        }
        .iframe_child {
          flex: 1 1 auto;
        }
        iframe {
          border-style: hidden;
        }
      "))
    )
  )

  server <- function(input, output, session) {

    app_name <- shiny::eventReactive({input$app_name}, {
      if (identical(input$app_name, "")) {
        req(FALSE)
      }
      if (! input$app_name %in% apps) {
        message("incorrect app name: '", input$app_name, "'")
        req(FALSE)
      }

      normalize_app_name(dir, apps, input$app_name, increment = FALSE)
    })

    go_to_next_app <- function() {
      next_app <- normalize_app_name(dir, apps, input$app_name, increment = TRUE)
      shiny::updateSelectizeInput(
        session,
        "app_name",
        selected = basename(next_app)
      )
    }

    shiny::observeEvent({input$accept}, {
      message("test_in_browser - | ", input$app_name)
      go_to_next_app()
    })

    shiny::observeEvent({input$reject}, {
      message("test_in_browser - X ", input$app_name)
      go_to_next_app()
    })


    app_proc <- NULL
    session$onSessionEnded(function() {
      if (!is.null(app_proc)) {
        message("Killing background Shiny Session")
        app_proc$kill()
      }
    })
    app_has_restarted <- shiny::eventReactive({input$refresh; app_name()}, {

      message("")
      message("Starting app: ", app_name())

      # kill prior app
      if (!is.null(app_proc)) {
        app_proc$kill()
      }

      port_is_available <- FALSE
      total_wait <- 2
      tries <- 20
      message("Testing background app port: ", port_background, "...", appendLF = FALSE)
      for (i in seq_len(tries)) {
        tryCatch(
          {
            s <- httpuv::startServer(host, port_background, list(), quiet = TRUE)
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
        stop("Port ", port_background, " was not available within ", total_wait, " seconds")
      }
      message(" OK")


      # start new app
      message("Launching background app process...", appendLF = FALSE)
      app_proc <<- callr::r_bg(
        function(app_dir_, port_, host_) {
          shiny::runApp(
            app_dir_,
            port = port_,
            host = host_,
            launch.browser = FALSE
          )
        },
        list(
          app_dir_ = app_name(),
          port_ = port_background,
          host_ = host
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
        paste0("http://", host, ":", port_background),
        pause_min = interval,
        pause_cap = interval,
        times = total_wait / interval,
        quiet = TRUE
      )
      message(" OK")

      TRUE
    })

    output_lines <- reactiveVal("")

    output$server_output <- renderText({
      output_lines()
    })

    observe({
      app_has_restarted()
      isolate({
        output_lines("")
      })
    })

    observe({
      app_has_restarted()
      shiny::invalidateLater(200)
      if (!is.null(app_proc)) {
        proc_output_lines <- app_proc$read_output_lines()
        if (any(nchar(proc_output_lines) > 0)) {
          isolate({
            output_lines(
              paste0(
                output_lines(),
                if (nchar(output_lines()) > 0) "\n",
                paste0(proc_output_lines, collapse = "\n")
              )
            )
          })
        }
      }
    })

    output$app_iframe <- renderUI({
      # trigger build
      app_has_restarted()

      shiny::tags$iframe(
        src = paste0("http://", host, ":", port_background, "/"),
        class = "iframe_child"
      )
    })
  }

  shiny::shinyApp(
    ui = ui,
    server = server,
    options = list(
      host = host,
      port = port,
      launch.browser = TRUE
    )
  )
}

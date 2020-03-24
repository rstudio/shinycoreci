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
#' @param host_background,port_background `host` and `port` for the background app process
#' @param app app number or name to start with. If numeric, it will match the leading number in the testing application
#' @param update_pkgs Logical that will try to automatically install packages. \[`TRUE`\]
#' @export
#' @examples
#' \dontrun{test_in_browser(dir = "apps")}
test_in_browser <- function(
  dir = "apps",
  apps = basename(apps_manual(dir)),
  app = apps[1],
  port_background = 8001,
  host_background = "127.0.0.1",
  delay = 1,
  update_pkgs = TRUE
) {
  sys_call <- match.call()
  force(update_pkgs)

  # if (rstudioapi::isAvailable()) {
  #   stop("This function should only be run outside the RStudio IDE")
  # }

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

  ui <- shiny::fluidPage(
    shiny::column(2,
      "App directory: ", dir,
      shiny::selectizeInput("app_name", "App", apps, selected = app),
      shiny::actionButton("accept", "Accept!"),
      shiny::actionButton("reject", "Reject"),
      shiny::verbatimTextOutput("server_output"),
      shiny::actionButton("refresh", "Refresh"),
    ),

    shiny::column(10,
      shiny::uiOutput("app_iframe", class = "iframe_container")
    ),

    shiny::tags$head(
      shiny::tags$style("
        body .container-fluid, body .col-sm-10 {
          padding-right: 0;
          padding-left: 0;
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
          border-left-style: solid;
          border-left-color: #f0f0f0;
        }

      ")
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

      # message("normalize_app_name: '", input$app_name, "'")
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


    # proc_env <- as.list(callr::rcmd_safe_env())
    # proc_env$R_BROWSER <- NULL
    # proc_env <- unlist(proc_env)
    app_proc <- NULL
    session$onSessionEnded(function() {
      if (!is.null(app_proc)) {
        message("Killing background Shiny Session")
        app_proc$kill()
      }
    })
    app_has_restarted <- shiny::eventReactive({input$refresh; app_name()}, {

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
            s <- httpuv::startServer(host_background, port_background, list(), quiet = TRUE)
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
      message("")
      message("Starting background app process...", appendLF = FALSE)
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
          host_ = host_background
        ),
        # env = proc_env,
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
      httr::RETRY("GET", paste0("http://", host_background, ":", port_background), pause_min = 0.25, pause_cap = 0.25, times = 10 / 0.25, quiet = TRUE)
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
          # cat(
          #   paste0("shinyproc - ", proc_output_lines, collapse = "\n"), "\n"
          # )
        }
      }
    })



    output$app_iframe <- renderUI({
      # trigger build
      app_has_restarted()

      shiny::tags$iframe(
        src = paste0("http://", host_background, ":", port_background, "/"),
        class = "iframe_child"
      )
    })
  }

  # shiny::runApp(
    shiny::shinyApp(ui = ui, server = server)
    # ,
  #   port = port,
  #   host = host,
  #   launch.browser = TRUE
  # )

}

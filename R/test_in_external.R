


test_in_external <- function(
  dir,
  app_infos,
  app,
  host = "127.0.0.1",
  port = 8080
) {

  # run shiny app in the browser
  if (rstudioapi::isAvailable()) {
    if (rstudioapi::isAvailable("1.3.387")) {
      # browser, window, pane
      shiny_viewer_type <- rstudioapi::readRStudioPreference("shiny_viewer_type", "not-correct")
      if (!identical(shiny_viewer_type, "browser")) {
        on.exit({
          rstudioapi::writeRStudioPreference("shiny_viewer_type", shiny_viewer_type)
        }, add = TRUE)
        rstudioapi::writeRStudioPreference("shiny_viewer_type", "browser")
      }
    } else {
      # RStudio, but early version
      # This feels hacky, but is necessary
      runExternal <- get(".rs.invokeShinyWindowExternal", envir = as.environment("tools:rstudio"))
      old_option <- options(shiny.launch.browser = runExternal)
      on.exit({
        options(old_option)
      })
    }
  }

  app_names <- vapply(app_infos, `[[`, character(1), "app_name")
  if (any(duplicated(app_names))) {
    utils::str(app_names[duplicated(app_names)])
    stop("Not all app names are unique!")
  }
  names(app_infos) <- app_names

  # double check that the remaining values exist as functions
  lapply(app_infos, function(app_info) {
    app_info_names <- names(app_info)
    for (
      name_val in c(
        "user_agent",
        "start",
        "on_session_ended",
        "output_lines",
        "header",
        "app_url"
      )
    ) {
      if (!is.function(app_info[[name_val]])) {
        stop("In app '", app_info$app_name, "': ", name_val, " is not a function")
      }
    }
  })

  # old_ops <- options(width = 100)
  # on.exit({
  #   options(old_ops)
  # }, add = TRUE)

  panel_width <- "350px"
  ui <- shiny::fluidPage(
    shiny::fixedPanel(
      class = "server_panel",
      shiny::tags$div(
        class = "apps_dir",
        shiny::uiOutput("header")
      ),
      shiny::selectizeInput("app_name", NULL, app_names, selected = basename(app)),
      shiny::tags$div(
        class = "button_container",
        shiny::uiOutput("jster_button"),
        shiny::uiOutput("solo"),
        shiny::actionButton("refresh", "Refresh", class = "refresh_button"),
        shiny::actionButton("reject", "Reject", class = "reject_button"),
        shiny::actionButton("accept", "Accept!", class = "accept_button"),
      ),
      shiny::verbatimTextOutput("server_output"),
      shiny::tags$script("
        $(function() {
          var wait = function() {
            if (Shiny.setInputValue) {
              Shiny.setInputValue('user_agent', window.navigator.userAgent);
              return;
            }
            setTimeout(wait, 10);
          }
          wait();
        })
      ")
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
          overflow-y: scroll;
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
        .button_container .solo_button:hover, .button_container .solo_button:active:hover {
          background-color: rgb(166, 221, 237);
        }
        .button_container .solo_button, .button_container .solo_button:hover, .button_container .solo_button:active:hover {
          border-color: rgb(38, 154, 188);
        }
        .button_container .jster_button:not(.disabled):hover, .button_container .jster_button:not(.disabled):active:hover {
          background-color: rgb(240, 212, 239);
        }
        .button_container .jster_button.disabled {
          color: #ccc;
        }
        .button_container .jster_button:not(.disabled), .button_container .jster_button:not(.disabled):hover, .button_container .jster_button:not(.disabled):active:hover {
          border-color: rgb(105, 0, 99);
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
        shiny::req(FALSE)
      }
      if (! input$app_name %in% app_names) {
        message("incorrect app name: '", input$app_name, "'")
        shiny::req(FALSE)
      }

      input$app_name
    })

    app_info <- shiny::reactive({
      app_infos[[app_name()]]
    })

    output$header <- shiny::renderUI({
      app_info()$header()
    })

    output_lines <- shiny::reactiveVal()

    user_agent <- shiny::reactive({
      shiny::req(input$user_agent)
      app_info()$user_agent(input$user_agent)
    })
    # observe right here to save the value once user_agent is valid.
    shiny::observe({
      app_status_init(dir, user_agent())
    })

    go_to_next_app <- function() {
      # get next app
      app_pos <- which(app_names == app_name()) + 1
      shiny::updateSelectizeInput(
        session,
        "app_name",
        selected = app_names[app_pos]
      )
    }

    shiny::observeEvent({input$accept}, {
      message("PASS ", app_name())
      app_status_save(
        app_dir = file.path(dir, app_name()),
        pass = TRUE,
        log = output_lines(),
        user_agent = user_agent()
      )
      go_to_next_app()
    })

    shiny::observeEvent({input$reject}, {
      message("FAIL ", app_name())
      app_status_save(
        app_dir = file.path(dir, app_name()),
        pass = FALSE,
        log = output_lines(),
        user_agent = user_agent()
      )
      go_to_next_app()
    })

    # Can not call app_info()$on_session_ended() directly as it requires a reactive context
    # That is not allowed in session$onSessionEnded
    on_session_ended <- NULL
    shiny::observe({
      if (!is.null(on_session_ended)) {
        # kill prior app session
        on_session_ended()
      }

      # save for later or for when the app changes
      on_session_ended <<- app_info()$on_session_ended
    })
    session$onSessionEnded(function() {
      if (! is.function(on_session_ended)) {
        return()
      }
      on_session_ended()
    })

    app_has_started <- shiny::eventReactive(
      {
        # trigger on refresh
        input$refresh
        # trigger on app name change
        app_name()
      },
      {
        app_info()$start()
      }
    )

    shiny::observe({
      # must have a value before allowing an invalidate later
      ret <- app_info()$output_lines()
      # check constantly
      shiny::invalidateLater(200)
      # set to output_lines to dedupe the value
      output_lines(ret)
    })
    # reset the output on refresh
    shiny::observeEvent({input$refresh}, {
      app_info()$output_lines(reset = TRUE)
      output_lines("")
    })
    output$server_output <- shiny::renderText({
      app_has_started()
      output_lines()
    })

    output$solo <- shiny::renderUI({
      shiny::tags$a(
        class = "btn btn-default solo_button",
        href = app_info()$app_url(),
        target = "_blank",
        "Solo"
      )
    })
    output$app_iframe <- shiny::renderUI({
      # trigger after starting
      app_has_started()

      shiny::tags$iframe(
        src = app_info()$app_url(),
        class = "iframe_child"
      )
    })

    output$jster_button <- shiny::renderUI({
      # try to find all shinyjster apps. Use `browser = 'external'` to not match any jster flags and return all possible apps
      if (app_info()$app_name %in% apps_shinyjster(dir)) {
        shiny::tags$a(
          class = "btn btn-default jster_button",
          href = paste0(app_info()$app_url(), "?shinyjster=1"),
          target = "_blank",
          "Jster"
        )
      } else {
        shiny::tags$a(
          class = "btn btn-default jster_button disabled",
          href = "#",
          "Jster"
        )
      }
    })
  }

  print(shiny::shinyApp(
    ui = ui,
    server = server,
    options = list(
      host = host,
      port = port,
      launch.browser = TRUE
    )
  ))
}

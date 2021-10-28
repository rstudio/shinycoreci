library(shiny)
enableBookmarking(store = "url")

library(htmltools)
library(dplyr)
library(tidyr)

# library(bslib)

# Pull in the repo location to view the test results
dir <- Sys.getenv("SHINYCORECI_VIEW_TEST_RESULTS", unset = "__unknown")
if (identical(dir, "__unknown")) {
  stop("This app must be called with `shinycoreci::view_test_results()")
}
repo_dir <- normalizePath(dir, mustWork = TRUE)
if ("shinycoreci-apps" != basename(repo_dir)) {
  warning("This function should be called from the shinycoreci-apps repo")
}
print(repo_dir)
curDir <- getwd()
on.exit(setwd(curDir), add = TRUE)
setwd(repo_dir)

strextract <- function(str, pattern) {
  regmatches(str, regexpr(pattern, str))
}


test_results <- memoise::memoise(function(files) {
  results <- lapply(files, test_results_import)
  bind_rows(results) %>%
    tibble::as_tibble() %>%
    mutate(gha_branch = gha_branch_name) %>%
    separate_("gha_branch_name", c("gha", "sha", "time", "r_version", "platform"), sep = "-") %>%
    select(-gha) %>%
    mutate(
      os = platform,
      platform = paste(platform, r_version, sep = "-"),
      time = as.POSIXct(time, format = "%Y_%m_%d_%H_%M"),
      date = as.Date(time),
      sha = paste0(branch_name, "@", sha)
    ) %>%
    arrange(desc(time))
})

test_results_import <- function(f) {
  json <- jsonlite::fromJSON(f)
  json$results$gha_branch_name <- json$gha_branch_name
  json$results$branch_name <- json$branch_name
  json$results
}




banner <- div(
  style = "display:flex; justify-content:center; gap:1rem; margin-top: 1rem",
  div("Showing", class = "lead text-large"),
  selectInput("platform", NULL, c("All platforms" = ""), multiple = TRUE),
  div("results between ", class = "lead text-large"),
  tagAppendAttributes(uiOutput("date_start"), style = "width:150px"),
  div(" and ", class = "lead text-large"),
  tagAppendAttributes(uiOutput("date_end"), style = "width:150px"),
  actionButton(
    "fetch_results", "Fetch results",
    icon = icon("cloud-download-alt"),
    class = "btn-primary btn-sm",
    style = "height:2.5rem"
  )
)

theme <- bslib::bs_theme(base_font = bslib::font_google("Prompt"))

ui <- fluidPage(
  theme = bslib::bs_add_rules(theme, ".nav-pills { @extend .justify-content-center; }"),
  tags$head(tags$style(HTML("
  .dataTables_filter {display: none};
  .result_app {padding: 0.5em; border-collapse: collapse;}
  .result_pass {background-color: #009469 !important;} /* green */
  .result_fail {background-color: #d95515 !important;} /* red */
  .result_can_not_install {background-color: #0066a7 !important;} /* blue */
  .result_did_not_return {background-color: #a3a3a3 !important;} /* white */
  .result_did_not_execute {background-color: #323232 !important;} /* black */
  .result_day td {border: 1px dotted grey;}
  .result_app > tbody > tr > td { }
  .result_day td {
    padding: 0.5rem !important;
    border-radius: 50%;
    /* No border */
  }
  .result_day {
    border-spacing: 1px;
    border-collapse: separate;
  }
  .result_app > tbody > tr > td {
      padding: 0px !important;
      padding-right: 6px !important;
  }

  /* Reduce title height */
  .form-group {
    margin-bottom: 0 !important;
  }
  .selectize-control {
    margin-bottom: 0 !important;
  }
"))),
  div(
    style = "display:flex; flex-direction: column; align-items: flex-start",
    banner,
    div(
      style = "width: 100%",
      DT::dataTableOutput("app_status_table")
    )
  )
)

server <- function(input, output, session) {
  # URL Bookmarking
  observe({
    # Trigger this observer every time an input changes
    reactiveValuesToList(input)
    session$doBookmark()
  })
  onBookmarked(function(url) {
    updateQueryString(url)
  })

  log_files <- reactive({
    if (isTRUE(input$fetch_results > 1) || TRUE) {
      shinycoreci:::git_cmd(repo_dir, "git fetch origin _test_results:_test_results")
      try({
        shinycoreci:::git_cmd(repo_dir, "git checkout _test_results -- _test_results/")
        shinycoreci:::git_cmd(repo_dir, "git reset _test_results/")
      })
    }
    withr::with_dir(repo_dir, normalizePath(Sys.glob("_test_results/*.json"), mustWork = TRUE))
  })

  log_dates <- reactive({
    as.Date(
      strextract(basename(log_files()), "[0-9]{4}_[0-9]{2}_[0-9]{2}"),
      format = "%Y_%m_%d"
    )
  })

  logs <- reactive({
    req(rng <- c(input$date_start, input$date_end))
    rng <- as.Date(rng)
    idx <- between(
      log_dates(),
      left = min(rng),
      right = max(rng)
    )
    test_results(log_files()[idx]) %>%
      filter(branch_name == "main")
  })

  platforms <- reactiveVal(c("All platforms" = ""), label = "platforms")
  observeEvent(logs(), {
    platforms_ <- platforms()
    platforms_ <- c(platforms_[1], sort(unique(c(platforms_[-1], unique(logs()$platform)))))
    platforms(platforms_)
  })
  observeEvent(platforms(), {
    updateSelectInput(session, "platform", choices = platforms())
  })

  output$date_start <- renderUI({
    rng <- range(log_dates())
    dateInput(
      "date_start", NULL, value = max(c(rng[2] - 10 + 1, rng[1])), min = rng[1], max = rng[2]
    )
  })

  output$date_end <- renderUI({
    rng <- range(log_dates())
    dateInput(
      "date_end", NULL, value = rng[2], min = rng[1], max = rng[2]
    )
  })

  logs_spread <- reactive({
    d <- logs()
    if (!is.null(input$platform)) {
      d <- filter(d, platform %in% input$platform)
    }
    d <- d %>%
      count(app_name, os, r_version, date, status, name = "n") %>%
      spread(status, n, fill = 0)
    if ("fail" %in% names(d)) {
      d <- arrange(d, desc(fail))
    }

    for (nme in c("can_not_install", "did_not_return_result", "fail", "pass")) {
      if (!rlang::has_name(d, nme)) {
        d[[nme]] <- 0
      }
    }

    d <- d %>%
      complete(
        app_name, os, r_version, date,
        fill = list(
          can_not_install = 0,
          did_not_return_result = 0,
          fail = 0,
          pass = 0
        )
      ) %>%
      mutate(
        not_executed = as.numeric(pass == 0 & fail == 0 & can_not_install == 0 & did_not_return_result == 0)
      )

    d
  })

  logs_summary <- reactive({
    d <- logs_spread() %>%
      group_by(app_name) %>%
      summarise(
        pass = sum(pass),
        fail = sum(fail),
        can_not_install = sum(can_not_install),
        did_not_return_result = sum(did_not_return_result),
        not_executed = sum(not_executed),
        .groups = "keep"
      )
    nms <- c(
      App = "app_name", Failures = "fail", Pass = "pass",
      "Can't install" = "can_not_install",
      "Skip test" = "did_not_return_result",
      "Not executed" = "not_executed"
    )
    nms <- nms[nms %in% names(d)]
    select(d, !!!nms)
  })

  logs_details <- reactive({
    d <-
      logs_spread() %>%
      mutate(
        cell_class = unlist(Map(
          pass, fail, can_not_install, did_not_return_result, not_executed,
          f = function(
            pass_, fail_, can_not_install_, did_not_return_result_, not_executed_
          ) {
            if (fail_ > 0) return("result_fail")
            if (pass_ > 0) return("result_pass")
            if (can_not_install_ > 0) return("result_can_not_install")
            if (did_not_return_result_ > 0) return("result_did_not_return_result")
            if (not_executed_ > 0) return("result_did_not_execute")
            str(list(
              fail_ = fail_,
              pass_ = pass_,
              can_not_install_ = can_not_install_,
              did_not_return_result_ = did_not_return_result_,
              not_executed_ = not_executed_
            ))
            stop("unknown state")
          }
        )),
        cell_status = c(
          "result_fail" = "Fail",
          "result_pass" = "Pass",
          "result_can_not_install" = "Could not install",
          "result_did_not_return_result" = "Did not test (ok)",
          "result_did_not_execute" = "Test did not execute (bad)"
        )[cell_class]
      )
    d_table <-
      d %>%
      # platform is horizontal
      group_by(app_name, date, r_version) %>%
      arrange(os, desc(r_version)) %>%
      summarise(
        .groups = "keep",
        rows = {
          list(do.call(
            tags$tr,
            Map(
              date, os, r_version, cell_status, cell_class,
              f = function(
                date_, os_, r_version_, cell_status_, cell_class_
              ) {
                tags$td(
                  class = "result_cell",
                  "data-toggle"="tooltip",
                  "data-html"="true",
                  title = paste0(os_, " ", r_version_, " - ", date_, "<br />", cell_status_),
                  class = cell_class_
                )
              }
            )
          ))
        }
      ) %>%
      group_by(app_name, date) %>%
      arrange(desc(r_version)) %>%
      summarise(
        per_date = {
          list(
            tags$table(rows, class = "result_day")
          )
        },
        .groups = "keep"
      ) %>%
      group_by(app_name) %>%
      arrange(date) %>%
      summarise(
        per_app = {
          list(
            tags$table(
              class = "result_app",
              tags$tr(
                lapply(per_date, tags$td)
              )
            )
          )
        },
        .groups = "keep"
      )

    d_table
  })

  logs_combined <-
    reactive({
      left_join(
        logs_summary(),
        logs_details(),
        by = c("App" = "app_name")
      ) %>%
      rename(Performance = per_app) %>%
      select(App, Performance, everything()) %>%
      mutate(
        Performance = lapply(Performance, function(p) { HTML(as.character(p)) } )
      )
    })



  output$app_status_table <- DT::renderDataTable({
    DT::datatable(
      logs_combined(),
      rownames = FALSE,
      selection = "single",
      filter = "top",
      fillContainer = TRUE,
      options = list(
        autoWidth = TRUE,
        columnDefs = list(list(width = '30px', targets = c(2,3,4,5,6))),

        info = FALSE, paging = FALSE, #searching = FALSE,
        scrollY = "80vh",
        order = list(list(2, 'desc')),

        # Init the tooltips
        drawCallback =  htmlwidgets::JS("
          function() {
            $('td[data-toggle=\"tooltip\"]').tooltip({
              // animated: 'fade',
            });
          }
        ")
      ),
      # Be able to use raw html
      escape = FALSE
    )
  })

  selected_app <- reactive({
    cell <- input$app_status_table_cell_clicked
    if (length(cell) > 0) {
      logs_summary()[cell$row, "App", drop = TRUE]
    }
  })

  app_logs <- reactive({
    req(selected_app())

    filter(
      logs(),
      app_name %in% selected_app(),
      status %in% c("fail", "can_not_install")
    )
  })

  selected_app_logs <- reactive({
    req(input$logs_date)
    filter(app_logs(), date == as.Date(input$logs_date))
  })

  observeEvent(input$app_status_table_cell_clicked, {

    logs <- app_logs()
    log_dates <- sort(unique(logs$date), decreasing = TRUE)

    # TODO: save GHA job id and create a hyperlink to
    # https://github.com/rstudio/shinycoreci-apps/runs/{job_id}
    # Better yet, can we link to either the build log or test source code?
    modal <- modalDialog(
      title = paste(selected_app(), "failure details"),
      size = "l",
      easyClose = TRUE,
      tabsetPanel(
        tabPanel(
          "Daily details",
          div(
            style = "display:flex; justify-content:center; gap:1rem",
            "Failure logs from:",
            selectInput(
              "logs_date", NULL, choices = log_dates
            )
          ),
          uiOutput("logs_report")
        ),
        tabPanel("Timeline", uiOutput("timeline")),
        type = "pills",
        header = br()
      )
    )

    showModal(modal)
  })

  output$timeline <- renderUI({
    validate(need(
      nrow(app_logs()) > 1,
      "No failures to show for this app"
    ))

    withr::with_namespace(
      "plotly", {

        panel <- . %>%
          plot_ly(height = 700) %>%
          add_bars(
            x = ~date, y = ~n, color = ~paste("R", r_version),
            legendgroup = ~r_version,
            showlegend = ~identical(unique(os), "Linux")
          ) %>%
          add_annotations(
            text = ~unique(os), showarrow = FALSE,
            x = 0.5, y = 1, yref = "paper", xref = "paper",
            yanchor = "bottom", font = list(size = 15),
            yshift = -3
          ) %>%
          layout(
            showlegend = FALSE,
            barmode = "stack",
            shapes = list(
              type = "rect",
              x0 = 0, x1 = 1, xref = "paper",
              y0 = 0, y1 = 16, yref = "paper",
              yanchor = 1, ysizemode = "pixel",
              fillcolor = toRGB("gray80"),
              line = list(color = "transparent")
            )
          )

        app_logs() %>%
          count(date, platform) %>%
          separate(platform, c("os", "r_version"), sep = "-") %>%
          group_by(os) %>%
          do(p = panel(.)) %>%
          subplot(nrows = NROW(.), shareX = TRUE) %>%
          layout(
            font = list(family = "Prompt", size = 14),
            showlegend = TRUE, hovermode = "x",
            yaxis2 = list(title = "Number of failures"),
            xaxis = list(title = ""),
            legend = list(orientation = "h", x = 1, xanchor = "right")
          ) %>%
          config(displayModeBar = FALSE)
      }
    )
  })

  output$logs_report <- renderUI({
    req(input$logs_date)

    logs <- selected_app_logs()
    logs <- split(logs, logs$platform)

    tagList(
      !!!Map(
        logs, names(logs),
        f = function(x, y) {
          res <- paste(x$result, collapse = "\n")
          tags$details(
            open = NA,
            tags$summary(y),
            tags$code(tags$pre(res))
          )
        }
      )
    )
  })

}

shinyApp(ui, server)

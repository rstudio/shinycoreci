### Keep this line to manually test this shiny application. Do not edit this line; shinycoreci::::is_manual_app

library(shiny)
library(future)
library(promises)
library(magrittr)
plan(multisession)


workers <- 2
future::plan("multisession", workers = workers)

n <- workers * 6
work_time <- 1


ui <- fluidPage(
  shinyjs::useShinyjs(),
  tags$style(HTML(
    "
    table, td {
      border: 1px solid black;
      border-collapse: collapse;
      padding: 5px;
    }
  "
  )),
  p(
    "This app tests that ",
    tags$code("promises::future_promise()"),
    " does not block the main R session in a shiny application."
  ),
  p(
    "The background counter value for ",
    tags$code("promises::future_promise()"),
    " should be higher than ",
    tags$code("future::future()"),
    "."
  ),
  uiOutput("status"),
  actionButton("go_future_future", "future::future()"),
  actionButton("go_future_promise", "promises::future_promise()"),
  tags$table(
    tags$tr(
      tags$td(tags$code("future::future()")),
      tags$td(
        "Background Count: ",
        verbatimTextOutput("future_counts", placeholder = TRUE)
      ),
      tags$td("Jobs:"),
      lapply(seq_len(n), function(i) {
        tags$td(
          verbatimTextOutput(paste0("future-", i), placeholder = TRUE)
        )
      }),
    ),
    tags$tr(
      tags$td(tags$code("promises::future_promise()")),
      tags$td(
        "Background Count: ",
        verbatimTextOutput("promise_counts", placeholder = TRUE)
      ),
      tags$td("Jobs:"),
      lapply(seq_len(n), function(i) {
        tags$td(
          verbatimTextOutput(paste0("promise-", i), placeholder = TRUE)
        )
      }),
    )
  )
)

server <- function(input, output, session) {
  future_counts <- reactiveVal()
  promise_counts <- reactiveVal()

  make_counter <- function(output_name, fn, react, counter_react) {
    print_counter <- reactiveVal(0)
    counter_val <- 0
    observeEvent(react(), {
      shinyjs::disable("go_future_future")
      shinyjs::disable("go_future_promise")

      this_session <- session

      message("start ", output_name, " counter")
      counter_val <<- 0
      print_counter()
      start <- Sys.time()
      do_counter <- function() {
        if (
          difftime(Sys.time(), start, units = "secs") >
            (n * work_time / workers + 1)
        ) {
          # counter(counter_val)
          isolate(counter_react(c(counter_react(), counter_val)))
          withReactiveDomain(this_session, {
            shinyjs::enable("go_future_future")
            shinyjs::enable("go_future_promise")
          })
          return()
        }
        counter_val <<- counter_val + 1
        message("increase ", output_name, " counter == ", counter_val)
        # counter(counter() + 1)
        later::later(do_counter, delay = 1 / 4)
      }
      do_counter()

      NULL
    })

    output[[paste0(output_name, "_counts")]] <- renderText({
      print_counter()
      counter_val
    })

    lapply(seq_len(n), function(i) {
      ith_val <- reactiveVal()
      observeEvent(react(), {
        message("start ", output_name, " - ", i)
        fn({
          Sys.sleep(work_time)
          message("done ", output_name, " - ", i)
          i
        }) %...>%
          {
            ith_val(.)
          }
        NULL
      })
      observeEvent(react(), {
        ith_val(" ")
      })
      output[[paste0(output_name, "-", i)]] <- renderText({
        # req(react())
        isolate(print_counter(print_counter() + 1))
        ith_val()
      })
    })
  }

  make_counter(
    "future",
    future::future,
    reactive({
      input$go_future_future
    }),
    future_counts
  )
  make_counter(
    "promise",
    future_promise,
    reactive({
      input$go_future_promise
    }),
    promise_counts
  )

  output$status <- renderUI({
    status <-
      if (length(future_counts()) < 1) {
        tagList("Click ", tags$code("future::future()"), " button")
      } else if (length(future_counts()) < 2) {
        tagList("Click ", tags$code("future::future()"), " button again")
      } else if (length(promise_counts()) < 1) {
        tagList("Click ", tags$code("promises::future_promise()"), " button")
      } else if (length(promise_counts()) < 2) {
        tagList(
          "Click ",
          tags$code("promises::future_promise()"),
          " button again"
        )
      } else {
        if (min(promise_counts()) > max(future_counts())) {
          "pass"
        } else {
          "fail"
        }
      }

    switch(
      as.character(status),
      "pass" = tags$h4(tags$span(
        "Pass!",
        style = "background-color: #7be092;"
      )),
      "fail" = tags$h4(tags$span(
        "Fail!",
        style = "background-color: #e68a8a;"
      )),
      tags$h4(tags$span(status, style = "background-color: #dddddd;"))
    )
  })
}

shinyApp(ui, server)

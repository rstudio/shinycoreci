library(shiny)
library(future)
library(promises)
library(magrittr)
plan(multisession)

ui <- fluidPage(
  p("This app tests that ", tags$code("invalidateLater()"), " calls are held until async operations are complete."),
  tags$ol(
    tags$li("You should see the number below increasing by 1, every 2 seconds."),
    tags$li("The output should be semi-transparent (i.e. recalculating state) continuously."),
    tags$li("You should see the word `'Flushed'` in the R console, every 2 seconds. And the `Flushed count` should be single value behind the `Counter` while executing")
  ),
  tags$h3("Counter:"),
  verbatimTextOutput("out", placeholder = TRUE),
  tags$h3("Flushed count:"),
  verbatimTextOutput("out_flushed", placeholder = TRUE),
  uiOutput("status")
)

server <- function(input, output, session) {
  value <- reactiveVal(0L)
  n <- 10

  start <- Sys.time()
  status <- reactiveVal("wait")

  observe({
    if (isolate(value()) < n) {
      invalidateLater(100)
    } else {
      diff_time <- as.difftime(Sys.time() - start, units = "secs")
      if (diff_time > ((n - 1) * 2)) {
        isolate({status("pass")})
      } else {
        isolate({status("fail")})
      }
    }
    isolate({ value(value() + 1L) })
  })

  output$status <- renderUI({
    switch(status(),
      "wait" = tags$h4(tags$span("Waiting...", style = "background-color: #dddddd;")),
      "pass" = tags$h4(tags$span("Pass!", style = "background-color: #7be092;")),
      tags$h4(tags$span("Fail!", style = "background-color: #e68a8a;"))
    )
  })

  flush_counter <- reactiveVal(0)
  session$onFlushed(function() {
    message("Flushed")
    isolate({ flush_counter(flush_counter() + 1L) })
  }, once = FALSE)
  output$out_flushed <- renderText({
    value()
    isolate(flush_counter())
  })

  output$out <- renderText({
    future(Sys.sleep(2)) %...>%
      { value() }
  })
}

shinyApp(ui, server)

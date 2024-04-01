library(shiny)
library(bslib)
library(shinyjster)

ui <- function(req) {
  page_sidebar(
    sidebar = sidebar(
      actionButton("calc1", "Recalc one"),
      hr(),
      actionButton("calc2", "Recalc two"),
      actionButton("calc2p", "Progress two"),
      actionButton("calc2e", "Error two"),
      actionButton("calc2a", "Abort two"),
      actionButton("calc2c", "Cancel output two"),
    ),
    shinyjster_js(readLines("test.js")),
    card(
      card_header("One"),
      plotOutput("plot1"),
    ),
    card(
      card_header("Two"),
      plotOutput("plot2")
    )
  )
}

server <- function(input, output, session) {
  shinyjster_server(input, output, session)

  output$plot1 <- renderPlot({
    input$calc1
    plot(runif(10), runif(10))
  })

  plot2state = reactiveVal("value")
  observeEvent(input$calc2, {
    plot2state("value")
  })
  observeEvent(input$calc2p, {
    plot2state("progress")
  })
  observeEvent(input$calc2e, {
    plot2state("error")
  })
  observeEvent(input$calc2a, {
    plot2state("abort")
  })
  observeEvent(input$calc2c, {
    plot2state("cancel")
  })

  output$plot2 <- renderPlot({
    input$calc2; input$calc2p; input$calc2e; input$calc2a; input$calc2c

    switch(plot2state(),
      value = NULL,
      progress = req(FALSE, cancelOutput="progress"),
      error = stop("boom"),
      cancel = req(FALSE, cancelOutput=TRUE),
      abort = req(FALSE),
    )

    plot(runif(10), runif(10))
  })
}

shinyApp(ui, server)

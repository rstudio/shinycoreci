ui <- fluidPage(
  p("This app tests whether radio buttons can have none selected, and that it is
    possible to update them to have none selected. "
  ),
  p(
    a("#2266", href="https://github.com/rstudio/shiny/issues/2266", .noWS = "after"),
    ", ",
    a("#2688", href="https://github.com/rstudio/shiny/issues/2688", .noWS = "after"),
    ", ",
    a("PR #3043", href="https://github.com/rstudio/shiny/pull/3043", .noWS = "after")
  ), 

  radioButtons("radio", "Radios", letters[1:5], selected = character(0)),
  actionButton("empty", "Empty"),
  verbatimTextOutput("txt"),

  tags$hr(),
  uiOutput("dynamic"),
  actionButton("rerender", "Re-Render dynamic radios"),
  verbatimTextOutput("txt2"),
)

server <- function(input, output, session) {
  observeEvent(input$empty, {
    updateRadioButtons(session, "radio", selected = character(0))
  })

  output$txt <- renderPrint({
    input$radio
  })
  
  output$dynamic <- renderUI({
    input$rerender
    radioButtons("radio2", "Dynamic radios", letters[1:5], selected = character(0))
  })

  output$txt2 <- renderPrint({
    input$radio2
  })
}

shinyApp(ui, server)

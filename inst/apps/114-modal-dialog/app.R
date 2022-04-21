shinyApp(
  ui = basicPage(
    # Make sure body height does not change when taking screenshots
    tags$style("body { min-height: 100vh; }"),
    actionButton("show", "Show modal dialog")
  ),
  server = function(input, output) {
    observeEvent(input$show, {
      showModal(modalDialog(
        title = "Important message",
        "This is an important message!",
        hr(),
        selectInput('selectizeInput', 'Selectize options', state.name, selectize=TRUE),
        easyClose = TRUE
      ))
    })
  }
)

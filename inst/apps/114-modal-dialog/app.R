shinyApp(
  ui = basicPage(
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

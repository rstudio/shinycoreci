library(shiny)
library(bslib)

ui <- page_fixed(
  title = "Keyboard Settings",
  h2("Keyboard Settings"),
  input_switch("auto_capitalization", "Auto-Capitalization", TRUE),
  input_switch("auto_correction", "Auto-Correction", FALSE),
  input_switch("check_spelling", "Check Spelling", TRUE),
  input_switch("smart_punctuation", "Smart Punctuation"),
  h2("Preview"),
  verbatimTextOutput("preview"),
  h2("Update Methods"),
  actionButton("toggle_spelling", "Toggle Spell Check"),
  actionButton("enable_auto_correct", "Enable Auto correct"),
  actionButton("disable_capitalization", "Disable Capitalization"),
  textInput("smart_punct_label", "Smart Punctuation Label", "Smart Punctuation")
)

server <- function(input, output, session) {
  output$preview <- renderPrint({
    list(
      auto_capitalization = input$auto_capitalization,
      auto_correction = input$auto_correction,
      check_spelling = input$check_spelling,
      smart_punctuation = input$smart_punctuation
    )
  })

  test_value_update <- function(...) {
    fn <- switch(
      getOption("value_update_type", "update"),
      update = update_switch,
      toggle_switch
    )

    eval(rlang::call2(fn, ...))
  }

  observeEvent(input$toggle_spelling, {
    toggle_switch("check_spelling")
  })

  observeEvent(input$enable_auto_correct, {
    test_value_update("auto_correction", value = TRUE)
  })

  observeEvent(input$disable_capitalization, {
    test_value_update("auto_capitalization", value = FALSE)
  })

  observeEvent(input$smart_punct_label, {
    update_switch("smart_punctuation", label = input$smart_punct_label)
  })
}

shinyApp(ui, server)

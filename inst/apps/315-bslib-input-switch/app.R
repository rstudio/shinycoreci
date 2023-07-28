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

  h2("toggle_switch()"),
  actionButton("toggle_spelling", "Toggle Spell Check"),
  actionButton("toggle_enable_auto_correct", "Enable Auto correct"),
  actionButton("toggle_disable_capitalization", "Disable Capitalization"),

  h2("update_switch()"),
  actionButton("update_toggle_spelling", "Toggle Spell Check"),
  actionButton("update_enable_auto_correct", "Enable Auto correct"),
  actionButton("update_disable_capitalization", "Disable Capitalization"),
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

  # toggle_switch() -----------------------------------------------------------

  observeEvent(input$toggle_spelling, {
    toggle_switch("check_spelling")
  })

  observeEvent(input$toggle_enable_auto_correct, {
    toggle_switch("auto_correction", value = TRUE)
  })

  observeEvent(input$toggle_disable_capitalization, {
    toggle_switch("auto_capitalization", value = FALSE)
  })

  # update_switch() -----------------------------------------------------------

  observeEvent(input$update_toggle_spelling, {
    update_switch("check_spelling", value = !input$check_spelling)
  })

  observeEvent(input$update_enable_auto_correct, {
    update_switch("auto_correction", value = TRUE)
  })

  observeEvent(input$update_disable_capitalization, {
    update_switch("auto_capitalization", value = FALSE)
  })

  observeEvent(input$smart_punct_label, {
    update_switch("smart_punctuation", label = input$smart_punct_label)
  })
}

shinyApp(ui, server)

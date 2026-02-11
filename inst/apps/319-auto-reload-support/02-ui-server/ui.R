library(shiny)

source("test-ui.R") # provides ui_text

fluidPage(
  h2(id = "ui_test", ui_text),
  textOutput("server_test"),
  p("Global: ", span(id = "global_test", global_text)),
  actionButton("update_files", "Update files")
)

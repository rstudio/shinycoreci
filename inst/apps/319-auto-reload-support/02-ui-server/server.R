source("test-server.R") # server_text

server <- function(input, output, session) {
  observeEvent(input$update_files, {
    writeLines('ui_text <- "UI test passed"', "test-ui.R")
    writeLines('server_text <- "Server test passed"', "test-server.R")
    writeLines('global_text <- "Global failed"', "test-global.R")
  })

  output$server_test <- renderText(server_text)
}

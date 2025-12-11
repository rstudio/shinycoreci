library(shiny)
options(shiny.autoreload = TRUE)

reset_test_supporting_files <- function() {
  message("Writing initial supporting files")
  writeLines('ui_text <- "UI test start"', "test-ui.R")
  writeLines('server_text <- "Server test start"', "test-server.R")
  writeLines('global_text <- "Global test start"', "test-global.R")
}

if (!file.exists("test-ui.R")) {
  reset_test_supporting_files()
}

source("test-global.R") # provides global_text

shiny::onStop(function() {
  unlink("test-ui.R")
  unlink("test-server.R")
  unlink("test-global.R")
})

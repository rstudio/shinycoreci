library(shiny)
options(shiny.autoreload = TRUE)

reset_test_supporting_file <- function() {
  message("Writing initial title.R")
  writeLines(
    "title <- 'Test start'",
    "title.R"
  )
}

if (!file.exists("title.R")) {
  reset_test_supporting_file()
}

source("title.R") # provides title

ui <- fluidPage(
  h2(id = "title", title),
  actionButton("update_title", "Update title")
)

server <- function(input, output, session) {
  observeEvent(input$update_title, {
    message("updating title.R")
    writeLines(
      'title <- "Test passed"',
      "title.R"
    )
  })
}

shiny::onStop(function() {
  if (file.exists("title.R")) {
    message("cleaning up title.R")
    unlink("title.R")
  }
})

shinyApp(ui, server)

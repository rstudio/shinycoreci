library(shiny)

ui <- fluidPage(
  p(
    "This app is meant to test encoding of JSON snapshots with shinytest.",
    a("Issue #206", href = "https://github.com/rstudio/shinytest/issues/206")
  ),
  selectInput("select", "Select", c("é", "å")),
  verbatimTextOutput("txt")
)

server <- function(input, output, session) {
  output$txt <- renderText({
    input$select
  })
}

shinyApp(ui, server)

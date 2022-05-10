library(shiny)

ui <- fluidPage(
  h3(tags$code("insertUI()"), " executes", tags$code("<script />"), "tags"),
  conditionalPanel("window.insert_ui_script",
    tags$h4(tags$span("Pass!", style = "background-color: #7be092;"))
  ),
  conditionalPanel("!window.insert_ui_script",
    tags$h4(tags$span("Fail!", style = "background-color: #e68a8a;"))
  ),
)

server <- function(input, output) {
  shinyjster::shinyjster_server(input, output)

  observe({
    insertUI(
      selector = "head",
      ui = tags$script("window.insert_ui_script = true")
    )
  })
}

shinyApp(ui, server)

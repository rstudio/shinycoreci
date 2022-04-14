library(shiny)

shiny::addResourcePath("js", "js")

ui <- fluidPage(
  uiOutput("message"),
  shinyjster::shinyjster_js(paste(collapse = "\n", readLines("shinyjster.js")))
)

server <- function(input, output, session) {
  shinyjster::shinyjster_server(input, output)

  output$message <- renderUI({
    htmltools::attachDependencies(
      "fail",
      htmltools::htmlDependency(
        name = "test",
        version = "1.0.0",
        src = "js",
        script = list(src = "test.js", type = "module", defer = NA)
      )
    )
  })
}

shinyApp(ui, server)

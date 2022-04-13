### Keep this line to manually test this shiny application. Do not edit this line; shinycoreci::::is_manual_app


library(shiny)

source("linked_scatter.R")

ui <- fixedPage(
  h2("Module example"),
  linkedScatterUI("scatters"),
  textOutput("summary")
)

server <- function(input, output, session) {
  df <- linkedScatterServer(
    "scatters",
    reactive(mpg),
    left = reactive(c("cty", "hwy")),
    right = reactive(c("drv", "hwy"))
  )

  output$summary <- renderText({
    sprintf("%d observation(s) selected", nrow(dplyr::filter(df(), selected_)))
  })
}

shinyApp(ui, server)

library(shiny)
library(ggplot2)
library(bslib)

ui <- page_fixed(
  card(
    card_header("Interactive Brushing Plot"),
    plotOutput("plot", brush = "plot_brush"),
    card_footer("Drag to select points on the plot")
  ),
  card(
    card_header("Selected Data Points"),
    tableOutput("brushed_data")
  )
)

server <- function(input, output, session) {

  output$plot <- renderPlot({
    ggplot(iris, aes(x = Sepal.Length, y = Sepal.Width, color = Species)) +
      geom_point(size = 3) +
      theme_minimal()
  })

  output$brushed_data <- renderTable({
    req(input$plot_brush)

    brushed_data <- brushedPoints(
      iris, input$plot_brush,
      xvar = "Sepal.Length", yvar = "Sepal.Width"
    )

    if(nrow(brushed_data) == 0) {
      return(data.frame(Message = "No points selected"))
    }

    brushed_data
  })
}

shinyApp(ui = ui, server = server)

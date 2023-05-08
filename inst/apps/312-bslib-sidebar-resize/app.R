### Keep this line to manually test this shiny application. Do not edit this line; shinycoreci::::is_manual_app

library(shiny)
library(bslib)
library(ggplot2)
library(plotly)

lorem1 <- p(
  "Dolor cursus quis sociis, tempus laoreet integer vel,",
  "nam suscipit sodales curabitur tristique. Hac massa",
  "fames auctor ac posuere, non: primis semper egestas!",
  "Porttitor interdum lobortis elementum arcu."
)

lorem2 <- p(
  "Elit aptent vivamus, eu habitasse fringilla venenatis",
  "viverra tellus metus. Maecenas ultrices fermentum",
  "nunc turpis libero nascetur!"
)

ui <- page_fixed(
  titlePanel("Sidebar Resize", "312 | bslib-sidebar-resize"),
  h2("Static plot resizing"),
  p(
    "The plot in the layout below should stretch while the sidebar is opening", "or closing. After the transition is complete, the server will update the",
    "plot with the final dimensions."
  ),
  layout_sidebar(
    sidebar = sidebar(title = "Toggle me", lorem1, lorem2, lorem1),
    lorem1,
    plotOutput("plot_static"),
    lorem2
  ),
  h2("Widget plot resizing", class = "mt-4 mb-2"),
  p(
    "The plot in the layout below should stretch while the sidebar is opening", "or closing. There should be no layout shift after the transition is", "complete."
  ),
  layout_sidebar(
    sidebar = sidebar(title = "Toggle me", lorem1, lorem2, lorem1),
    lorem1,
    plotlyOutput("plot_widget"),
    lorem2
  ),
  div(style = "min-height: 100vh")
)

server <- function(input, output, session) {
  plot <- reactive({
    ggplot(mtcars, aes(mpg, wt)) + geom_point()
  })

  output$plot_static <- renderPlot(plot())
  output$plot_widget <- renderPlotly(ggplotly(plot()))
}

shinyApp(ui, server)

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

ui <- page_navbar(
  title = "312 | bslib-sidebar-resize",
  theme = bs_theme(
    "bslib-sidebar-transition-duration" = Sys.getenv("SIDEBAR_TRANSITION_TIME", "0.5s")
  ),
  sidebar = sidebar(
    title = "Shared Sidebar",
    id = "sidebar-shared",
    open = "open",
    p("The plots should resize smoothly when this sidebar or the local sidebar are toggled.")
  ),
  nav_panel(
    "Static",
    h2("Static plot resizing"),
    p(
      "The plot in the layout below should stretch while the sidebar is",
      "opening or closing. After the transition is complete, the server will",
      "update the plot with the final dimensions."
    ),
    layout_sidebar(
      sidebar = sidebar(
        title = "Toggle me",
        id = "sidebar-local-static",
        lorem1, lorem2, lorem1
      ),
      lorem1,
      plotOutput("plot_static_local"),
      lorem2
    ),
    h2("Shared only", class = "my-3"),
    p(
      "The next plot should resize smoothly only when the shared sidebar is transitioning."
    ),
    div(
      class = "row",
      div(class = "col-6", plotOutput("plot_static_shared")),
      div(class = "col-6", lorem2, lorem1)
    )
  ),
  nav_panel(
    "Widget",
    h2("Widget plot resizing"),
    p(
      "The plot in the layout below should stretch while the sidebar is opening",
      "or closing. There should be no layout shift after the transition is",
      "complete."
    ),
    layout_sidebar(
      sidebar = sidebar(
        title = "Toggle me",
        id = "sidebar-local-widget",
        lorem1, lorem2, lorem1
      ),
      lorem1,
      plotlyOutput("plot_widget_local"),
      lorem2
    ),
    h2("Shared only", class = "my-3"),
    p(
      "The next plot should resize smoothly only when the shared sidebar is transitioning."
    ),
    div(
      class = "row",
      div(class = "col-6", plotlyOutput("plot_widget_shared")),
      div(class = "col-6", lorem2, lorem1)
    )
  ),
  nav_panel(
    "Client",
    h2("Client-side htmlwidget resizing"),
    p(
      "The plot in the layout below should stretch while the sidebar is opening",
      "or closing. There should be no layout shift after the transition is",
      "complete."
    ),
    layout_sidebar(
      sidebar = sidebar(
        title = "Toggle me",
        id = "sidebar-local-client",
        lorem1, lorem2, lorem1
      ),
      lorem1,
      div(id = "plot_client_local", plot_ly(x = rnorm(100))),
      lorem2
    ),
    h2("Shared only", class = "my-3"),
    p(
      "The next plot should resize smoothly only when the shared sidebar is transitioning."
    ),
    div(
      class = "row",
      div(
        class = "col-6",
        div(id = "plot_client_shared", plot_ly(x = rnorm(100)))
      ),
      div(class = "col-6", lorem2, lorem1)
    )
  ),
  footer = div(style = "min-height: 100vh")
)

server <- function(input, output, session) {
  observeEvent(input$open_sidebar_shared, {
    sidebar_toggle("sidebar-shared", open = "open")
  })

  plot <- reactive({
    ggplot(mtcars, aes(mpg, wt)) +
      geom_point(aes(color = factor(cyl))) +
      labs(
        title = "Cars go brrrrr",
        x = "Miles per gallon",
        y = "Weight (tons)",
        color = "Cylinders"
      ) +
      theme_gray(base_size = 16)
  })

  output$plot_static_local <- renderPlot(plot())
  output$plot_static_shared <- renderPlot(plot())

  output$plot_widget_local <- renderPlotly(ggplotly(plot()))
  output$plot_widget_shared <- renderPlotly(ggplotly(plot()))
}

shinyApp(ui, server)

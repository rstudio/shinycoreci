library(shiny)
library(bslib)
library(plotly)

ui <- page_navbar(
  title = "Tooltip tests",
  fillable = FALSE,
  id = "navbar",
  theme = bs_theme("tooltip-bg" = "#232529"),

  nav_panel(
    "Tooltip cases",
    inputPanel(
      class = "px-3 py-5",
      h3("Placement"),
      tooltip(
        a("auto", id = "tip-auto", href = "#"),
        "Tooltip title"
      ),
      tooltip(
        a("left", id = "tip-left", href = "#"),
        "Tooltip title",
        placement = "left"
      ),
      tooltip(
        a("right", id = "tip-right", href = "#"),
        "Tooltip title",
        placement = "right"
      ),
      tooltip(
        a("top", id = "tip-top", href = "#"),
        "Tooltip title",
        placement = "top"
      ),
      tooltip(
        a("bottom", id = "tip-bottom", href = "#"),
        "Tooltip title",
        placement = "bottom"
      )
    ),

    inputPanel(
      class = "px-3 py-5",
      h3("Triggers"),
      tooltip(id = "tip-hello",
        "Hello tooltip",
        "Tooltip message"
      ),
      tooltip(id = "tip-inline",
        span("Inline tooltip"),
        "Tooltip message"
      ),
      tooltip(id = "tip-action",
        actionButton("btn", "A button"),
        "Tooltip 1"
      ),
      tooltip(id = "tip-multiple",
        tagList(
          actionButton("btn2", "A button"),
          actionButton("btn3", "A button"),
        ),
        "A tooltip"
      )
    ),

    inputPanel(
      class = "px-3 py-5",
      h3("Options"),
      tooltip(
        span("Offset (50,50)", id = "tip-offset"),
        "This tip should appear 50px down/right",
        placement = "right",
        options = list(offset = c(50, 50))
      ),
      tooltip(
        span("Offset (50,50)", id = "tip-animation"),
        "This tip shouldn't fade in/out",
        placement = "right",
        options = list(animation = FALSE)
      )
    ),

  ),

  nav_panel(
    "Tooltip updates",
    layout_sidebar(
      card(
        card_header(
          span(
            "Card title with tooltip",
            bsicons::bs_icon("question-circle-fill")
          ) |>
            tooltip(
              "Tooltip message", id = "tooltip",
              placement = "right"
            )
        ),
        plotlyOutput("bars")
      ),
      sidebar = list(
        textInput("tooltip_msg", "Enter a tooltip message", "Tooltip message"),
        actionButton("show_tooltip", "Show tooltip", class = "mb-3"),
        actionButton("hide_tooltip", "Hide tooltip")
      )
    )
  ),
)

server <- function(input, output, session) {

  observeEvent(input$tooltip_msg, {
    update_tooltip("tooltip", input$tooltip_msg)
  })

  observeEvent(input$show_tooltip, {
    toggle_tooltip("tooltip", show = TRUE)
  })

  observeEvent(input$hide_tooltip, {
    toggle_tooltip("tooltip", show = FALSE)
  })

  output$bars <- renderPlotly({
    plot_ly(diamonds, x = ~cut)
  })

}

shinyApp(ui, server)


library(shiny)
library(bslib)
library(crosstalk)
library(plotly)

plotly_bars <- plot_ly(x = LETTERS[1:3], y = 1:3) %>%
  add_bars()

sidebar_long <- sidebar(lorem::ipsum(3, 3))
sidebar_short <- sidebar(
  p("A simple sidebar"),
  actionButton("foo", "This button does nothing")
)

ui <- page_navbar(
  title = "Sidebar kitchen sink",
  fillable = c("Fill", "Fill+Scroll", "Global card sidebar"),
  id = "navbar",
  sidebar = sidebar(
    open = FALSE,
    position = "right",
    id = "global_sidebar",
    bg = "#1E1E1E",
    shiny::markdown(
      "Learn more about `bslib::sidebar()` [here](https://rstudio.github.io/bslib/articles/sidebars.html)"
    )
  ),
  header = tagList(
    tags$style(HTML(".plotly .modebar-container { display: none; }")),
    span("header", class = "bg-dark"),
    span("content", class = "bg-dark")
  ),
  footer = tagList(
    span("footer", class = "bg-dark"),
    span("content", class = "bg-dark")
  ),
  nav(
    "Fill",
    plotly_bars,
    br(),
    layout_sidebar(sidebar_short, plotly_bars, fillable = TRUE),
    br(),
    card(
      card_header("Depth"),
      layout_sidebar(sidebar_short, plotly_bars, fillable = TRUE)
    )
  ),
  nav(
    "Fill+Scroll",
    plotly_bars,
    br(),
    layout_sidebar(sidebar_long, plotly_bars),
    br(),
    card(
      card_header("Depth"),
      layout_sidebar(sidebar_long, plotly_bars)
    )
  ),
  nav(
    "Scroll",
    plotly_bars,
    br(),
    layout_sidebar(sidebar_long, plotly_bars),
    br(),
    card(
      card_header("Depth"),
      layout_sidebar(sidebar_long, plotly_bars)
    )
  ),
  nav(
    "Global card sidebar",
    # Wrapping this up with layout_column_wrap() should keep
    # the row height the same (even when switch tabs)
    layout_column_wrap(
      width = 1,
      navs_tab_card(
        title = "Global sidebar",
        id = "card_tab_sidebar",
        sidebar = sidebar_long,
        full_screen = TRUE,
        nav("Tab 1", plotly_bars, plotly_bars),
        nav("Tab 2", plotly_bars)
      ),
      navs_pill_card(
        title = "Global sidebar",
        id = "card_pill_sidebar",
        sidebar = sidebar_long,
        full_screen = TRUE,
        nav("Pill 1", plotly_bars, plotly_bars),
        nav("Pill 2", plotly_bars)
      )
    )
  ),
  nav_spacer(),
  nav_item(actionButton("toggle_sidebar", "Learn more"))
)


server <- function(input, output) {

  observeEvent(input$toggle_sidebar, {
    sidebar_toggle("global_sidebar")
  })

}

shinyApp(ui, server)

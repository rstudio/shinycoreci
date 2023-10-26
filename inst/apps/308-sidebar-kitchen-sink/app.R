library(shiny)
library(bslib)
library(crosstalk)
library(plotly)

plotly_bars <- plot_ly(x = LETTERS[1:3], y = 1:3) %>%
  add_bars()

sidebar_long <- sidebar(lorem::ipsum(3, 3))
sidebar_short <- local({
  i <- 0
  function() {
    i <<- i + 1
    sidebar(
      p("A simple sidebar"),
      actionButton(sprintf("foo-%d", i), "This button does nothing")
    )
  }
})

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
    # Disable sidebar transitions for tests
    tags$style(
      id = "disable-sidebar-transition",
      ":root {--bslib-sidebar-transition-duration: 0ms};"
    ),
    tags$style(HTML(".plotly .modebar-container { display: none; }")),
    span("header", class = "bg-dark"),
    span("content", class = "bg-dark")
  ),
  footer = tagList(
    span("footer", class = "bg-dark"),
    span("content", class = "bg-dark")
  ),
  nav_panel(
    "Fill",
    plotly_bars,
    layout_sidebar(plotly_bars, sidebar = sidebar_short()),
    card(
      card_header("Depth"),
      layout_sidebar(plotly_bars, sidebar = sidebar_short())
    )
  ),
  nav_panel(
    "Fill+Scroll",
    plotly_bars,
    card(
      card_header("Depth"),
      layout_sidebar(plotly_bars, sidebar = sidebar_long)
    ),
    layout_sidebar(plotly_bars, sidebar = sidebar_long)
  ),
  nav_panel(
    "Scroll",
    plotly_bars,
    card(
      card_header("Depth"),
      layout_sidebar(plotly_bars, sidebar = sidebar_long)
    ),
    layout_sidebar(plotly_bars, sidebar = sidebar_long)
  ),
  nav_panel(
    "Global card sidebar",
    # Wrapping this up with layout_column_wrap() should keep
    # the row height the same (even when switch tabs)
    layout_columns(
      col_widths = 12,
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

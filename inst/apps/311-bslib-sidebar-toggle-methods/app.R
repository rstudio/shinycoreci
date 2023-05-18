# A VERSION OF THIS APP IS ALSO USED IN 310-bslib-sidebar-dynamic
library(shiny)
library(bslib)

color_pairs <- list(
  list(dark = "#1A2A6C", light = "#AED9E0"),
  list(dark = "#800020", light = "#F6DFD7"),
  list(dark = "#4B0082", light = "#E6E6FA"),
  list(dark = "#006D5B", light = "#A2D5C6")
)
adjectives <- c(
  "charming", "cuddly", "elegant", "fierce", "graceful",
  "majestic", "playful", "quirky", "silly", "witty"
)
animals <- c(
  "elephant", "giraffe", "jaguar", "koala", "lemur",
  "otter", "panda", "panther", "penguin", "zebra"
)

sb <- layout_column_wrap(
  width = 500,
  id = "sidebar-here",
  layout_sidebar(
    id = "main_outer",
    sidebar = sidebar(
      "Outer Sidebar",
      id = "sidebar_outer",
      width = 150,
      bg = color_pairs[[1]]$dark,
      open = "desktop",
      max_height_mobile = "300px",
      selectInput(
        "adjective",
        "Adjective",
        choices = adjectives,
        selected = adjectives[1]
      )
    ),
    height = 300,
    class = "p-0",
    fillable = TRUE,
    layout_sidebar(
      id = "main_inner",
      sidebar = sidebar(
        "Inner Sidebar",
        id = "sidebar_inner",
        width = 150,
        bg = color_pairs[[1]]$light,
        open = "desktop",
        selectInput(
          "animal",
          "Animal",
          choices = animals,
          selected = animals[1]
        )
      ),
      border = FALSE,
      border_radius = FALSE,
      h2("Sidebar Layout"),
      uiOutput("ui_content", tabindex = 0)
    )
  )
)

ui <- page_fixed(
  h1("Dynamic Sidebars"),
  tags$head(tags$title("bslib | Tests | Dynamic Sidebars")),
  p(
    "Test tab focus order: main, inner sidebar, outer sidebar.",
    "Test server-side open and close of sidebars."
  ),
  tagAppendAttributes(sb, class = "mb-4", id = "layout"),
  div(
    class = "my-2",
    actionButton("show_all", "Show all"),
    actionButton("toggle_inner", "Toggle inner"),
    actionButton("toggle_outer", "Toggle outer")
  )
)

server <- function(input, output, session) {
  output$ui_content <- renderUI({
    p(sprintf("Hello, %s %s!", input$adjective, input$animal))
  })

  observeEvent(input$show_all, {
    sidebar_toggle("sidebar_inner", open = TRUE)
    sidebar_toggle("sidebar_outer", open = TRUE)
  })

  observeEvent(input$toggle_inner, {
    sidebar_toggle("sidebar_inner")
  })

  observeEvent(input$toggle_outer, {
    sidebar_toggle("sidebar_outer")
  })
}

shinyApp(ui, server)

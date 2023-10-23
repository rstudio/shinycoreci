
library(shiny)
library(bslib)

# If TRUE, the app starts with a sidebar present, which means that the sidebar
# javascript is available on page load. Use this option for debugging the js.
# In the first test, we don't include sidebars to test dynamic dep loading.
INCLUDE_INITIAL_SIDEBAR <- Sys.getenv("INCLUDE_INITIAL_SIDEBAR", FALSE)

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

# Creates a nested sidebar layout with 2 left-aligned sidebars. Each sidebar has
# one input and the main content area has one output that combines the inputs.
nested_sidebar <- function(idx = 0L) {
  colors <- color_pairs[[idx %% length(color_pairs) + 1]]
  open <- c("desktop", "open", "closed")[idx %% 3 + 1]

  select_adjective <- function() {
    selectInput(
      paste0("adjective_", idx),
      "Adjective",
      choices = adjectives,
      selected = adjectives[idx %% length(adjectives) + 1]
    )
  }

  select_animal <- function() {
    selectInput(
      paste0("animal_", idx),
      "Animal",
      choices = animals,
      selected = animals[idx %% length(animals) + 1]
    )
  }

  sb <- layout_sidebar(
    id = paste0("main_outer_", idx),
    sidebar = sidebar(
      "Outer Sidebar",
      id = paste0("sidebar_outer_", idx),
      width = 150,
      bg = colors$dark,
      open = open,
      max_height_mobile = "300px",
      select_adjective()
    ),
    height = 300,
    class = "p-0",
    fillable = TRUE,
    layout_sidebar(
      id = paste0("main_inner_", idx),
      sidebar = sidebar(
        "Inner Sidebar",
        id = paste0("sidebar_inner_", idx),
        width = 150,
        bg = colors$light,
        open = open,
        select_animal()
      ),
      border = FALSE,
      border_radius = FALSE,
      h2("Sidebar Layout", idx),
      uiOutput(paste0("ui_content_", idx))
    )
  )

  tagAppendAttributes(sb, class = "mb-4", id = paste0("layout_", idx))
}

ui <- page_fixed(
  h1("Dynamic Sidebars"),
  tags$head(tags$title("bslib | Tests | Dynamic Sidebars")),
  # Disable sidebar transitions for tests
  tags$style(".bslib-sidebar-layout {--bslib-sidebar-transition-duration: 0};"),
  p(
    "Test dynamically added sidebars.",
    "Each new layout is a nested layout with two sidebars.",
    "The sidebar collapse toggles should not overlap when collapsed.",
    "Added sidebars rotate through open, closed, and desktop initial states.",
    "If you add a \"desktop\" sidebar while in mobile screen width",
    "(every 3rd addition), the sidebars will be closed when added."
  ),
  layout_column_wrap(
    width = 500,
    id = "sidebar-here",
    if (INCLUDE_INITIAL_SIDEBAR) nested_sidebar()
  ),
  div(
    class = "my-2",
    actionButton("add_sidebar", "Add sidebar layout"),
    actionButton("remove_sidebar", "Remove sidebar layout")
  ),
  div(
    class = "my-2",
    actionButton("show_all", "Show all"),
    actionButton("toggle_last_inner", "Toggle last inner"),
    actionButton("toggle_last_outer", "Toggle last outer")
  )
)

server <- function(input, output, session) {
  idx <- 0L
  has_sidebar <- INCLUDE_INITIAL_SIDEBAR

  output_nested_sidebar <- function(idx) {
    output_id <- paste0("ui_content_", idx)
    adjective_id <- paste0("adjective_", idx)
    animal_id <- paste0("animal_", idx)

    output[[output_id]] <- renderUI({
      p(sprintf("Hello, %s %s!", input[[adjective_id]], input[[animal_id]]))
    })
  }

  if (INCLUDE_INITIAL_SIDEBAR) {
    observe({
      isolate(output_nested_sidebar(0))
    })
  }

  observeEvent(input$add_sidebar, {
    if (idx == 0) has_sidebar <<- TRUE
    idx <<- idx + 1L

    insertUI(
      selector = "#sidebar-here",
      where = "beforeEnd",
      ui = nested_sidebar(idx)
    )

    output_nested_sidebar(idx)
  })

  observeEvent(input$remove_sidebar, {
    removeUI(selector = "#sidebar-here > :last-child")
  })

  observeEvent(input$show_all, {
    req(has_sidebar)
    ids <- grep("^sidebar_", names(input), value = TRUE)
    for (id in ids) {
      message("opening ", id)
      sidebar_toggle(id, open = TRUE)
    }
  })

  observeEvent(input$toggle_last_inner, {
    req(has_sidebar)
    sidebar_toggle(paste0("sidebar_inner_", idx))
  })

  observeEvent(input$toggle_last_outer, {
    req(has_sidebar)
    sidebar_toggle(paste0("sidebar_outer_", idx))
  })
}

shinyApp(ui, server)

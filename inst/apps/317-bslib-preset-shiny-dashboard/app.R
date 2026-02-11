library(shiny)
library(bslib)
library(htmltools)

options(
  sass.cache = FALSE,
  shiny.autoreload = TRUE,
  shiny.testmode = TRUE,
  bslib.precompiled = FALSE
)

toggle_class_buttons <- HTML('
<fieldset>
<legend class="fs-5 border-bottom">Body Classes</legend>
<div class="form-check form-switch">
    <input
      class="form-check-input body-class-toggle"
      type="checkbox"
      id="dashboard_toggle"
      data-class="bslib-page-dashboard"
      onchange="document.body.classList.toggle(this.dataset.class, this.checked)"
    >
    <label class="form-check-label" for="dashboard_toggle">Dashboard Class</label>
</div>
<div class="form-check form-switch">
    <input
      class="form-check-input body-class-toggle"
      type="checkbox"
      id="shadow_toggle"
      data-class="bslib-card-box-shadow-none"
      onchange="document.body.classList.toggle(this.dataset.class, this.checked)"
    >
    <label class="form-check-label" for="shadow_toggle">No Shadow Class</label>
</div>
<div class="form-check form-switch">
    <input
      class="form-check-input body-class-toggle"
      type="checkbox"
      id="shadow_sm_toggle"
      data-class="bslib-card-box-shadow-sm"
      onchange="document.body.classList.toggle(this.dataset.class, this.checked)"
    >
    <label class="form-check-label" for="shadow_sm_toggle">Small Shadow Class</label>
</div>
<div class="form-check form-switch">
    <input
      class="form-check-input body-class-toggle"
      type="checkbox"
      id="shadow_lg_toggle"
      data-class="bslib-card-box-shadow-lg"
      onchange="document.body.classList.toggle(this.dataset.class, this.checked)"
    >
    <label class="form-check-label" for="shadow_lg_toggle">Large Shadow Class</label>
</div>
</fieldset>
')


global_sidebar <- function(..., fg = NULL, bg = NULL) {
  sidebar(
    title = "Sidebar",
    fg = fg,
    bg = bg,
    "Shared sidebar",
    input_dark_mode(id = "dark_mode"),
    ...,
    toggle_class_buttons
  )
}

card_a_nav <-
  navset_card_underline(
    title = "A Nav Card",
    sidebar = sidebar(
      title = "Sidebar A",
      width = "200px",
      position = "left",
      "Left sidebar"
    ),
    nav_panel("One", plotly::plotlyOutput("bars")),
    nav_panel("Two", "Second panel in the nav card")
  )

card_a <-
  card(
    card_header("A Card"),
    layout_sidebar(
      fillable = TRUE,
      sidebar = sidebar(
        title = "Sidebar A",
        width = "200px",
        position = "left",
        "Left sidebar"
      ),
      plotly::plotlyOutput("bars")
    ),
    card_footer("Footer A")
  )

card_b <-
  card(
    card_header("B Card"),
    layout_sidebar(
      sidebar = sidebar(
        title = "Sidebar B",
        width = "200px",
        position = "right",
        "Right sidebar"
      ),
      plotly::plotlyOutput("line")
    ),
    card_footer("Footer B")
  )

row_cards <- layout_columns(card_a_nav, card_b)

row_value_boxes <-
  layout_columns(
    row_heights = "minmax(100px, 1fr)",
    value_box(
      "First",
      "Thing One",
      showcase = bsicons::bs_icon("pin-angle-fill")
    ),
    value_box(
      "Second",
      "Thing Two",
      showcase = bsicons::bs_icon("boombox-fill")
    )
  )

ui_navbar <- function(enable_dashboard = TRUE) {
  page_navbar(
    title = "Dashboard",
    theme = bs_global_get(),
    fillable = TRUE,
    sidebar = global_sidebar(),
    nav_spacer(),
    nav_panel(
      "Page",
      row_value_boxes,
      row_cards
    )
  )
}

ui_navbar_fillable <- function(...) {
  page_navbar(
    title = "Dashboard",
    theme = bs_global_get(),
    fillable = TRUE,
    nav_spacer(),
    nav_item(input_dark_mode(id = "dark_mode")),
    nav_item(
      popover(
        bsicons::bs_icon("gear-fill"),
        toggle_class_buttons
      )
    ),
    nav_panel(
      "Dash",
      row_value_boxes,
      row_cards
    ),
    nav_panel(
      "About",
      layout_columns(
        card(
          card_title("About this"),
          lorem::ipsum(3, 2)
        ),
        card(
          card_title("About that"),
          lorem::ipsum(4, c(2, 1, 3, 2))
        )
      )
    )
  )
}

ui_sidebar <- function(enable_dashboard = TRUE) {
  page_sidebar(
    title = "Dashboard",
    theme = bs_global_get(),
    sidebar = global_sidebar(),
    # bg = "green",
    row_value_boxes,
    row_cards
  )
}

ui_fillable_navbar <- function(enable_dashboard = TRUE) {
  page_fillable(
    theme = bs_global_get(),
    gap = 0,
    padding = 0,
    class = if (enable_dashboard) "bslib-page-dashboard",
    navset_bar(
      title = "Dashboard",
      sidebar = global_sidebar(),
      nav_spacer(),
      nav_panel(
        "Page",
        class = "p-0 m-0",
        row_value_boxes,
        row_cards
      ) |> htmltools::tagAppendAttributes(class = "m-0")
    )
  )
}

ui_fillable_sidebar <- function(enable_dashboard = TRUE) {
  page_fillable(
    theme = bs_global_get(),
    gap = 0,
    padding = 0,
    class = if (enable_dashboard) "bslib-page-dashboard",
    layout_sidebar(
      sidebar = global_sidebar(),
      h2("Dashboard"),
      row_value_boxes,
      row_cards
    ) |> htmltools::tagAppendAttributes(class = "m-0")
  )
}

abs_dark_mode <- input_dark_mode(
  id = "dark_mode",
  style = htmltools::css(
    position = "absolute",
    top = "1em",
    right = "1em"
  )
)

ui_flow_dash <- function(enable_dashboard = TRUE) {
  set.seed(2023*11*15)

  p <- page_fluid(
    theme = bs_global_get(),
    h2("Fluid Dashboard Page", class = "my-4"),
    row_value_boxes,
    lorem::ipsum(2, 2),
    row_cards,
    abs_dark_mode,
    toggle_class_buttons
  )

  if (!enable_dashboard) return(p)

  # In the tests, the dashboard class is added w/ client-side JS, but it could
  # be done manually by directly calling body. This path is not directly tested,
  # but is included for symmetry with the other UIs and for manual testing.
  tags$body(class = "bslib-page-dashboard", p)
}

ui_flow_sidebar <- function(enable_dashboard = TRUE) {
  set.seed(2023*11*15)

  p <- page_fixed(
    theme = bs_global_get(),
    h2("Fixed Dashboard Page"),
    layout_sidebar(
      sidebar = global_sidebar(),
      row_value_boxes,
      lorem::ipsum(2, 2),
      row_cards
    )
  )

  if (!enable_dashboard) return(p)

  tags$body(class = "bslib-page-dashboard", p)
}

ui_fillable_nested <- function(enable_dashboard = TRUE) {
  page_fillable(
    class = if (enable_dashboard) "bslib-page-dashboard main",
    theme = bs_global_get(),
    row_value_boxes,
    card(
      card_header("Outer Plots Card"),
      class = "p-0",
      layout_sidebar(
        sidebar = global_sidebar(),
        row_cards
      )
    )
  )
}

server <- function(input, output, session) {
  plotly_defaults <- function(p) {
    p <- plotly::layout(
      p,
      margin = list(l = 0, r = 0, t = 0, b = 0),
      font = list(
        family = "Open Sans",
        color = if (input$dark_mode == "dark") "white" else "#1D1F21"
      ),
      yaxis = list(gridcolor = if (input$dark_mode == "dark") "#303030"),
      xaxis = list(gridcolor = if (input$dark_mode == "dark") "#303030"),
      plot_bgcolor = "transparent",
      paper_bgcolor = "transparent"
    )

    plotly::config(p, displayModeBar = FALSE)
  }

  output$bars <- plotly::renderPlotly({
    plotly::plot_ly(
      data.frame(
        x = factor(1:5, labels = c("Fair", "Good", "Better", "Best", "Ideal")),
        y = c(1610, 5002, 13234, 16905, 21551)
      ),
      x = ~x,
      y = ~y
    ) |>
    plotly_defaults()
  })

  output$line <- plotly::renderPlotly({
    set.seed(4323)

    plotly::plot_ly(
      data.frame(
        x = seq.Date(as.Date("2020-01-01"), as.Date("2021-01-01"), by = "day"),
        y = cumsum(rnorm(367, sd = 4))
      ),
      x = ~x,
      y = ~y,
      type = "scatter",
      mode = "lines"
    ) |>
      plotly_defaults()
  })
}

ui <- function(req) {
  q <- parseQueryString(req$QUERY_STRING)
  if (is.null(q$ui)) q$ui <- "navbar"
  q$ui <- gsub("-", "_", q$ui)
  if (is.null(q$preset)) q$preset <- "shiny"
  if (is.null(q$dashboard_class)) q$dashboard_class <- FALSE

  args <- list(
    version = 5,
    preset = q$preset,
    bslib_dashboard_design = q[["dashboard"]],
    bslib_enable_shadows = q[["shadows"]]
  )

  cli::cli_h1("New app scenario")
  cli::cli_dl(c(args, dashboard_class = q$dashboard_class))

  do.call(bs_global_theme, purrr::compact(args))

  switch(
    q$ui,
    navbar = ui_navbar(q$dashboard_class),
    sidebar = ui_sidebar(q$dashboard_class),
    fillable_navbar = ui_fillable_navbar(enable_dashboard = q$dashboard_class),
    fillable_sidebar = ui_fillable_sidebar(enable_dashboard = q$dashboard_class),
    flow_dash = ui_flow_dash(enable_dashboard = q$dashboard_class),
    flow_sidebar = ui_flow_sidebar(enable_dashboard = q$dashboard_class),
    fillable_nested = ui_fillable_nested(enable_dashboard = q$dashboard_class),
    navbar_fillable = ui_navbar_fillable()
  )
}

shinyApp(ui, server)

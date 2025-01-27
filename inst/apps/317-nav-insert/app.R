library(shiny)
library(bslib)

DO_ALERT <- FALSE

action_choices <- c(
  "Singleton script" = "singleton",
  "Scripts with singleton" = "scripts",
  "HTML Widget" = "htmlwidgets",
  "Input/Output (content)" = "input_output_content",
  "Input/Output (nav)" = "input_output_nav",
  "Shiny sub-app" = "subapp"
)

ui <- page_navbar(
  title = "Reprex for #4179",
  id = "main",
  lang = "en",
  navbar_options = navbar_options(collapsible = FALSE),
  footer = absolutePanel(
    card(
      selectInput("insert_type", "Insert nav type", choices = action_choices),
      actionButton("do_insert", "Insert Nav"),
      HTML(
        '<p>Scripts: <span id="script-count">0</span> evaluated (<span id="script-count-expected">0</span> expected).'
      ),
      tags$script(
        HTML(
          "Shiny.addCustomMessageHandler('script-count-expected', function(value) {
            const exp = document.getElementById('script-count-expected')
            exp.textContent = +exp.textContent + value;
          })"
        )
      )
    ),
    bottom = "1rem",
    right = "1rem",
    draggable = TRUE
  )
)

# https://github.com/rstudio/shiny/pull/1794#issuecomment-318722200
# We need these test cases for anywhere we insert dynamic UI:

# 1. `<script>` blocks should run
# 2. `<script>` blocks should only run once
# 3. `head()`/`singleton()` should be respected
# 4. HTML widgets should work
# 	a. Even when the dependencies are not part of the initial page load
# 5. Shiny inputs/outputs should work
# 6. Subapps should work (include a `shinyApp` object right in the UI)

action_link <- shiny::actionLink("refresh", "Refresh")

script_hello_world <- local({
  i <- 0

  function() {
    i <<- i + 1

    shiny::HTML(
      "<script>(function() {
        const el = document.getElementById('script-count')
        el.textContent = +el.textContent + 1
      })()</script>"
    )
  }
})

script_singleton <- shiny::singleton(script_hello_world())

singleton_has_run <- FALSE

nav_insert_singleton <- function(session) {
  if (!singleton_has_run) {
    session$sendCustomMessage('script-count-expected', 1L)
    singleton_has_run <<- TRUE
  }

  nav_insert(
    id = "main",
    select = TRUE,
    nav_panel(
      "One",
      p("Script should only run the first time this nav is inserted."),
      # 1. script blocks should run
      script_singleton,
      # 3. head() should be respected
      tags$head(tags$meta(content = "shiny-test-head"))
    ),
  )
}

nav_insert_scripts <- function(session) {
  session$sendCustomMessage('script-count-expected', 2L)

  nav_insert(
    id = "main",
    select = TRUE,
    nav_panel(
      value = "Two",
      tagList(
        "Two",
        script_hello_world(),
      ),
      p(
        "Two scripts should run every time this nav is inserted."
      ),
      # 2. script blocks should only run once
      script_hello_world()
    ),
  )
}

nav_insert_htmlwidget <- local({
  widget_count <- 0
  function() {
    widget_count <<- widget_count + 1
    # 4. htmlwidgets work even if not part of initial page load
    nav_insert(
      id = "main",
      select = TRUE,
      nav_panel(
        "Map",
        leaflet::addTiles(
          leaflet::leaflet(
            elementId = sprintf("leaflet-%d", widget_count)
          )
        )
      ),
    )
  }
})

nav_insert_input_output_content <- function(input, output) {
  # 5. Input/outputs should work (in content)
  nav_insert(
    id = "main",
    select = TRUE,
    nav_panel(
      "Inputs/outputs",
      layout_columns(
        actionButton("btn", "Click me"),
        sliderInput("slider", "Slide me", min = 0, max = 10, value = 2),
      ),
      verbatimTextOutput("debug")
    )
  )

  output$debug <- renderPrint({
    list(
      btn = input$btn,
      slider = input$slider,
      nav_link = input$nav_link
    )
  })
}

nav_insert_input_output_nav <- function(input, output) {
  # 5. Inputs/outputs work (in navbar)
  nav_insert(
    id = "main",
    nav_item(
      actionLink("nav_link", "Click me too", class = "nav-link")
    )
  )

  nav_insert(
    id = "main",
    nav_item(textOutput("nav_output"))
  )

  output$nav_output <- renderText({
    sprintf("Clicked %d times", input$nav_link)
  })
}

nav_insert_subapp <- function() {
  # 6. Shiny subapps
  nav_insert(
    id = "main",
    select = TRUE,
    nav_panel(
      "Shiny app",
      p("There should be another shiny app in here."),
      shinyApp(
        ui = page_fluid(
          theme = bs_theme(preset = "darkly"),
          titlePanel("Hello from in here!"),
          p("This is a sub-app. Notice we're re-using the btn id."),
          actionButton("btn", "Click me"),
          verbatimTextOutput("debug")
        ),
        server = function(input, output, session) {
          output$debug <- renderPrint(list(btn = input$btn))
        }
      )
    )
  )
}

server <- function(input, output, session) {
  choices <- reactiveVal(action_choices)

  observe({
    updateSelectInput(
      session,
      "insert_type",
      choices = choices(),
      selected = input$insert_type
    )
  })

  observeEvent(input$do_insert, {
    one_time_choice <- FALSE

    switch(
      input$insert_type,
      "singleton" = nav_insert_singleton(session),
      "scripts" = nav_insert_scripts(session),
      "htmlwidgets" = nav_insert_htmlwidget(),
      "input_output_content" = {
        one_time_choice <- TRUE
        nav_insert_input_output_content(input, output)
      },
      "input_output_nav" = {
        one_time_choice <- TRUE
        nav_insert_input_output_nav(input, output)
      },
      "subapp" = nav_insert_subapp()
    )

    if (one_time_choice) {
      choices(choices()[choices() != input$insert_type])
    }
  })
}

shinyApp(ui, server)

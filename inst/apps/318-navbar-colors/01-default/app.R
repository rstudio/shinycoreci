library(shiny)
library(bslib)

VERSION <- Sys.getenv("TEST_VERSION", "5")
PRESET <- Sys.getenv("TEST_PRESET", "shiny")

pre_code <- function(x) {
  HTML(sprintf("<pre><code>%s</code></pre>", x))
}

ui <- page_navbar(
  title = "My Simple App",
  theme = bs_theme(
    preset = PRESET,
    version = VERSION
  ),
  nav_panel(
    "Home",
    h2("Default navbar"),
    pre_code(
      sprintf('bs_theme(%s, preset="%s")', VERSION, PRESET)
    ),
    p("Default navbar colors without any customization."),
    if (VERSION >= 5) {
      bslib::input_dark_mode(mode = "light", id = "color_mode")
    }
  ),
  nav_panel(
    "About",
    h2("About navbars")
  )
)

server <- function(input, output, session) {
}

shinyApp(ui, server)

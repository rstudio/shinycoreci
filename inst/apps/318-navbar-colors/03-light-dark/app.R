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
    version = VERSION,
    navbar_light_bg = "#b2d8ff",
    navbar_dark_bg = "#00165d",
  ),
  nav_panel(
    "Home",
    h2("Light/dark background color (Sass)"),
    pre_code(
      sprintf(
        'bs_theme(%s, preset="%s", navbar_light_bg = "#b2d8ff", navbar_dark_bg = "#00165d")',
        VERSION,
        PRESET
      )
    ),
    p(
      "Test light/dark navbar background color variants set via $navbar-light-bg and $navbar-dark-bg."
    ),
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

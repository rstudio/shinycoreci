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
    navbar_bg = "#732400",
  ),
  nav_panel(
    "Home",
    h2("Constant background color (Sass)"),
    pre_code(
      sprintf(
        'bs_theme(%s, preset="%s", navbar_bg="#732400")',
        VERSION,
        PRESET
      )
    ),
    p(
      "Test constant navbar background color set via $navbar-bg.",
      "Navbar should be the same color in all variations regardless of preset."
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

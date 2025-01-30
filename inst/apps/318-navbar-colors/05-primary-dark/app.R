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
  ),
  navbar_options = navbar_options(class = "bg-primary", theme = "dark"),
  nav_panel(
    "Home",
    h2("Using class and theme"),
    pre_code(
      sprintf('bs_theme(%s, preset="%s")', VERSION, PRESET)
    ),
    p(
      "Navbar background color is set via",
      code(
        'navbar_options = navbar_options(class = "bg-primary", theme = "dark")'
      ),
      "and should have the primary color as the background with light-colored text."
    ),
    if (VERSION >= 5) {
      bslib::input_dark_mode(
        mode = "light",
        id = "color_mode",
        style = css("--speed-fast" = 0, "--speed-normal" = 0)
      )
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

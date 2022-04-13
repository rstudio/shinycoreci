# NOTE: this script is shared amongst apps 181-185. If you update
# something here, it likely needs to be updated in the other apps as well

library(shiny)
library(htmltools)

# Register font for use with showtext and ragg
# NOTE: these were downloaded via `gfonts::download_font("pacifico", "www/fonts")`
#sysfonts::font_add("Pacifico", "fonts/pacifico-v16-latin-regular.ttf")
#systemfonts::register_font("Pacifico", "fonts/pacifico-v16-latin-regular.ttf")

# Now enable showtext so that font can render with a non-ragg renderPlot()
#showtext::showtext_auto()
#onStop(function() { showtext::showtext_auto(FALSE) })

# Set up CSS styles using a structure that getCurrentOutputInfo() should return
font <- list(
  # BS4 families
  families = c("-apple-system", "system-ui", "Segoe UI", "Roboto", "Helvetica Neue", "Arial", "Noto Sans", "sans-serif", "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji"),
  size = "10px"
)

info1 <- list(
  bg = "#000000",
  fg = "#FFFFFF",
  accent = "#00FF00",
  font = font
)

info2 <- list(
  bg = "#008080",
  fg = "#0000FF",
  accent = "#000000",
  font = font
)

to_json <- function(x, ...) {
  jsonlite::toJSON(x, auto_unbox = TRUE, ...)
}

# Translate R lists to CSS
info2css <- function(info, selector = "body") {
  tagList(
    tags$style(HTML(sprintf(
      "%s {color: %s; background-color: %s; font-family: '%s'; font-size: %s}",
      selector, info$fg, info$bg, paste(info$font$families, collapse = "', '"),
      info$font$size
    ))),
    tags$style(HTML(sprintf(
      "%s a {color: %s}",
      selector, info$accent
    )))
  )
}

display_in_row <- function(x, y) {
  fluidRow(column(6, x), column(6, y))
}

do_image <- function(family = "Pacifico", height, width, ratio) {
  png("tmp.png", height = height()*ratio(), width = width()*ratio(), res = 72*ratio())
  do_plot(family = family)
  dev.off()
  list(src = "tmp.png", height = 150, width = "100%")
}

do_plot <- function(family = "Pacifico") {
  info <- getCurrentOutputInfo()
  par(bg = info$bg())
  plot(1, type = "n")
  msg <- if (identical(family, "Pacifico")) {
    "This text should appear in cursive"
  } else {
    "This text should NOT appear in cursive"
  }
  text(1, msg, family = family, col = info$fg())
}

create_testing_app <- function(ui, server) {
  shinyApp(
    fluidPage(
      info2css(info1, "body"),
      info2css(info2, "#info2"),
      ui
    ),
    server
  )
}

render_image <- function(expr, session) {
  snapshotPreprocessOutput(
    renderImage(expr, deleteFile = TRUE),
    function(value) {}
  )
}

render_plot <- function(expr) {
  # bg arg is necessary because CairoPNG() doesn't respect par(bg=...)
  snapshotPreprocessOutput(
    if (isTRUE(getOption("shiny.usecairo"))) renderPlot(expr, bg = info1$bg) else renderPlot(expr),
    function(value) {}
  )
}

image_testing_app <- function() {
  create_testing_app(
    display_in_row(
      imageOutput("pacifico", height = 150),
      imageOutput("default", height = 150)
    ),
    function(input, output, session) {
      height <- reactive(session$clientData$output_pacifico_height)
      width <- reactive(session$clientData$output_pacifico_width)
      ratio <- reactive(session$clientData$pixelratio)
      output$pacifico <- render_image(do_image(family = "Pacifico", height = height, width = width, ratio))
      output$default <- render_image(do_image(family = "", height = height, width = width, ratio))
    }
  )
}

plot_testing_app <- function() {
  create_testing_app(
    display_in_row(
      plotOutput("pacifico", height = 150),
      plotOutput("default", height = 150)
    ),
    function(input, output) {
      output$pacifico <- render_plot(do_plot())
      output$default <- render_plot(do_plot(family = ""))
    }
  )
}

png_testing_app <- function() {
  opts <- options(shiny.usecairo = FALSE, shiny.useragg = FALSE)
  onStop(function() { options(opts) })
  plot_testing_app()
}

cairo_testing_app <- function() {
  library(Cairo)
  opts <- options(shiny.usecairo = TRUE, shiny.useragg = FALSE)
  onStop(function() { options(opts) })
  plot_testing_app()
}

ragg_testing_app <- function() {
  library(ragg)
  opts <- options(shiny.useragg = TRUE, shiny.usecairo = FALSE)
  onStop(function() { options(opts) })
  plot_testing_app()
}

### Keep this line to manually test this shiny application. Do not edit this line; shinycoreci::::is_manual_app


library(promises)
library(shiny)

ui <- function(req) {
  fluidPage(
    # This is here just to make sure the slider's HTML dependencies are populated
    # in the documents <head>.
    htmltools::htmlDependencies(sliderInput("ignore_me", "Isn't used", 0, 1, 0.5)),
    h2("Bookmarking of dynamic inputs"),
    p("(For ",
      a(href = "https://github.com/rstudio/shiny/pull/2139", "#2139"), ", ",
      a(href = "https://github.com/rstudio/shiny/pull/2360", "#2360"),
      ")"
    ),
    p("Change the slider value below, then make a bookmark URL.",
      "Navigate to that URL and ensure that the slider value is restored correctly.",
      "Then, in the new browser window, change the slider and click on Reset Slider.",
      "Make sure the slider returns to the original value of 5."),
    uiOutput("ui"),
    actionButton("reset", "Reset Slider"),
    bookmarkButton()
  )
}

server <- function(input, output, session) {
  output$ui <- renderUI({
    p <- promise(function(resolve, reject) {
      input$reset

      # We'll try to consume input$x here with async just to make sure that
      # the delay doesn't cause the input$x to be flushed from the
      # restoreContext and make input$x not be restored in the next step in
      # the promise chain.
      sliderInput("x", "x", 1, 10, 5)

      resolve(TRUE)
    })

    p <- p$then(function(value) {
      sliderInput("x", "x", 1, 10, 5)
    })

    p
  })

  # When running in Shinytest, we need to display a consistent port number for
  # snapshots. (This URL won't actually work for restoring a bookmark.)
  if (isTRUE(getOption("shiny.testmode"))) {
    onBookmarked(function(url) {
      url <- sub(":\\d+/", ":9999/", url)
      showBookmarkUrlModal(url)
    })
  }
}

enableBookmarking("url")

shinyApp(ui, server)


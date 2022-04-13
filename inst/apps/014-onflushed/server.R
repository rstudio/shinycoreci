function(input, output, session) {

  values <- reactiveValues(starting = TRUE)

  # This construction, using later() in onFlushed(), is used only because
  # shinytest will not take snapshots when the shiny process is busy. This
  # allows us to make sure onFlushed() is called, and also delay setting
  # values$starting to TRUE, without blocking the shiny process, which will
  # allow shinytest to take a snapshot in the waiting phase.

  session$onFlushed(function() {
    later::later(function() {
      values$starting <- FALSE
    }, 2)
  })

  output$fast <- renderText({ "This happens right away" })

  output$slow <- renderText({
    if (values$starting) {
      "Please wait for 2 seconds"
    } else {
      "This happens later"
    }
  })

  output$slow_plot <- renderPlot({
    if (values$starting) {
      plot(cars, main = "Please wait for a while")
    } else {
      plot(rnorm(100000), main = "A slow plot")
    }
  })

}

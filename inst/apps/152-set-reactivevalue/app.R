library(shiny)

# Create a nested list, which is slow to print with str()
obj <- lapply(1:60, function(i) {
  lapply(1:60, function(j) {
    list(i, j)
  })
})


shinyApp(
  ui = fluidPage(
    p("This is a test for ", a("#2375",href = "https://github.com/rstudio/shiny/issues/2375"),
      ". The elapsed time should be small, less than 0.5 seconds."),
    htmlOutput("txt"),
    shinyjster::shinyjster_js("
      var jst = jster();
      jst.add(Jster.shiny.waitUntilStable);
      jst.add(function() {
        Jster.assert.isTrue(
          /Pass/.test(
            $('#txt').text().trim()
          )
        );
      });

      jst.test();
    ")
  ),

  server = function(input, output, session) {
    shinyjster::shinyjster_server(input, output, session)

    start <- as.numeric(Sys.time())
    r <- reactiveValues(x = 1)

    observe({
      r$x <- obj
    })

    compute_time <- reactive({
      r$x
      round(as.numeric(Sys.time()) - start, 2)
    })

    output$txt <- renderUI({
      if (compute_time() < 0.5)
        status <- tags$b("Pass: ", style = "color: green;")
      else
        status <- tags$b("Fail: ", style = "color: red;")

      p(
        status,
        paste("Finished in", compute_time(), "seconds.")
      )
    })
  }
)

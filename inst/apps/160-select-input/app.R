library(shiny)

shinyApp(
  ui = fluidPage(
    p(
      "This test ensures that", code("selectInput()"), "doesn't introduce extra input variable(s).",
      a("Issue #2396", href = "https://github.com/rstudio/shiny/issues/2396"), "/",
      a("PR #2418", href = "https://github.com/rstudio/shiny/pull/2418")
    ),
    selectInput("variable", "Variable:",
                c("Cylinders" = "cyl", "Transmission" = "am", "Gears" = "gear")
    ),
    uiOutput("testResult"),
    shinyjster::shinyjster_js("
      var jst = jster();
      jst.add(Jster.shiny.waitUntilStable);

      jst.add(function() {
        Jster.assert.isEqual(
          $('#res').text().trim(),
          'passed'
        );
      });

      jst.test();
    ")
  ),
  server = function(input, output, session) {
    shinyjster::shinyjster_server(input, output, session)

    output$testResult <- renderUI({
      input$variable

      inputNames <- names(.subset2(input, "impl")$toList())
      # remove shinyjster inputs
      nInputs <- length(inputNames[!grepl("^jster_", inputNames)])
      if (nInputs == 1) {
        tags$b("Test", tags$span(id = "res", "passed"), ", move along", style = "color: green")
      } else {
        p(
          tags$b("Test", tags$span(id = "res", "failed"), ": ", style = "color: red"),
          "expected one input value, but got ",
          nInputs
        )
      }
    })
  }

)

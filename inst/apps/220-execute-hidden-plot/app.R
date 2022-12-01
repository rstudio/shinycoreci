library(shiny)

ui <- bslib::page_fluid(
  div(
    style = "display:none",
    plotOutput("plot")
  ),
  uiOutput("result"),
  shinyjster::shinyjster_js("
    var jst = jster(0);
    jst.add(Jster.shiny.waitUntilStable);

    // wait for result to be populated
    jst.add(function(done) {
      var wait = function() {
        if ($('#result span').length > 0) {
          done();
        } else {
          setTimeout(wait, 5);
        }
      }
      wait();
    });

    jst.add(function() {
      Jster.assert.isEqual(
        $('#result span').text(), 'Test passed :)',
        'The reactive expression for the hidden plot did not execute'
      );
    });

    jst.test();
  ")
)

server <- function(input, output, session) {

  shinyjster::shinyjster_server(input, output)

  has_run <- reactiveVal(FALSE)

  output$plot <- renderPlot({
    has_run(TRUE)
    plot(1)
  })

  outputOptions(output, "plot", suspendWhenHidden = FALSE)

  output$result <- renderUI({
    span(
      class = if (has_run()) "bg-success" else "bg-danger",
      if (has_run()) "Test passed :)" else "Test failed :("
    )
  })
}

shinyApp(ui = ui, server = server)

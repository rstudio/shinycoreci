library(shiny)

ui <- withTags(fluidPage(
  h3("Test of additional renderPlot args"),
  ol(
    li("The background of the plot should be the same color as the page background."),
    li("Try resizing the browser's width, make sure it's transparent even after redraw.")
  ),
  style("body { background-color: #A3E4D7; }"),
  plotOutput("plot"),

  shinyjster::shinyjster_js(set_timeout = FALSE, "

    // Given an img tag object, return the proportion of pixels that have zero
    // alpha.
    function proportion_transparent(id) {
      var data = Jster.image.data(id);

      // Count number of pixels with zero alpha
      var zeros = 0;
      for(var i = 0, n = data.length; i < n; i += 4) {
        var alpha = data[i + 3];
        if (alpha == 0) {
          zeros++;
        }
      }

      // Proportion of zero to non-zero-alpha pixels.
      return zeros / (data.length/4);
    }

    var jst = jster(1);
    jst.add(function(done) {
      var wait = function() {
        if ($('#plot img').length) {
          done();
        } else {
          setTimeout(wait, 50);
        }
      }
      wait();
    });

    jst.add(function() {
      Jster.assert.isTrue(
        proportion_transparent('plot') >= 0.95,
        {
          context: 'Plot is not >= 95% transparent'
        }
      );
    });

    jst.test();
  ")
))

server <- function(input, output, session) {
  shinyjster::shinyjster_server(input, output, session)

  output$plot <- renderPlot({
    par(bg = NA)
    plot(cars)
  }, bg = NA)
}

shinyApp(ui, server)

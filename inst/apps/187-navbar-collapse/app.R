library(shiny)

msg <- tags$h6(
  "If it isn't already, make your window narrow enough so that a menu appears above (and to the right). ",
  "Clicking that menu should show (and hide) a nav dropdown. ",
  "Confirm that the nav dropdown can be shown/hidden, and that you can click",
  "'Summary' to view a data summary (and 'Plot' to see a plot)."
)

jster <- shinyjster::shinyjster_js(
  "
    var jst = jster(0);
    jst.add(Jster.shiny.waitUntilStable);

    jst.add(function() {
       var toggle = $('.navbar-toggle:visible');
       var nav    = $('.navbar-collapse:visible');

       Jster.assert.isEqual(toggle.length, 1, 'Failed to find collapsible menu, does the window need to be resized?');
       Jster.assert.isEqual(nav.length, 0, 'The collapsible navbar should not be visible by default');
       toggle.click();
    });

    // wait for nav to open
    jst.add(function(done) {
      var wait = function() {
        if ($('.navbar-collapse:visible').length > 0) {
          done();
        } else {
          setTimeout(wait, 5);
        }
      }
      wait();
    });

    jst.add(function() {
      Jster.assert.isEqual(
        $('.navbar-collapse:visible').length, 1,
        'Clicking the navbar toggle should make the navbar appear.'
      );
    });

    jst.test();
    "
)

ui <- navbarPage(
  theme = bslib::bs_global_get(),
  "", collapsible = TRUE,
  tabPanel("Plot", msg, plotOutput("plot")),
  tabPanel("Summary", msg, verbatimTextOutput("summary"), jster)
)

server <- function(input, output, session) {
  shinyjster::shinyjster_server(input, output, session)

  output$plot <- renderPlot(plot(cars))
  output$summary <- renderPrint(summary(cars))
}

shinyApp(ui, server)

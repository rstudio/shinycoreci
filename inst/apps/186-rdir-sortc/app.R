shinyApp(
  ui = fluidPage(
    shinyjster::shinyjster_js("
      var jst = jster();
      jst.add(Jster.shiny.waitUntilStable);

      jst.add(function() {
        Jster.assert.isEqual(
          $('#text').text().trim(),
          'File load order: C, b, á'
        );
      });

      jst.test();
    "),
    p(
      "The purpose of this app is to make sure files loaded by loadSupport() are sorted using the C locale. ",
      a("PR 2872", href = "https://github.com/rstudio/shiny/pull/2872")
    ),
    p('The order of the letters below should be, "C, b, á"'),
    verbatimTextOutput("text")
  ),
  server = function(input, output, session) {
    shinyjster::shinyjster_server(input, output)
    output$text <- renderText({
      paste0("File load order: ", paste0(test_vector, collapse = ", "))
    })
  }
)

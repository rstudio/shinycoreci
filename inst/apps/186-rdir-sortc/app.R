shinyApp(
  ui = fluidPage(
    shinyjster::shinyjster_js("
      var jst = jster();
      jst.add(Jster.shiny.waitUntilStable);

      jst.add(function() {
        Jster.assert.isEqual(
          $('#text').text().trim(),
          'File load order: B_, C, b'
        );
      });

      jst.test();
    "),
    p(
      "The purpose of this app is to make sure files loaded by loadSupport() are sorted using the C locale. ",
      a("PR 2872", href = "https://github.com/rstudio/shiny/pull/2872")
    ),
    p(
      " Not using utf-8 file names as", tags$code("R CMD check"), "does not like these file names."
    ),
    p('The order of the letters below should be, "B_, C, b"'),
    verbatimTextOutput("text")
  ),
  server = function(input, output, session) {
    shinyjster::shinyjster_server(input, output)
    output$text <- renderText({
      paste0("File load order: ", paste0(test_vector, collapse = ", "))
    })
  }
)

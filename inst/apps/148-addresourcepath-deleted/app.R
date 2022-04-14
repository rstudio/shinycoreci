library(shiny)

tempdir <- tempfile("test")
dir.create(tempdir)
addResourcePath("my_test_prefix", tempdir)
unlink(tempdir, recursive = TRUE)

ui <- fluidPage(
  HTML("This app tests whether deleting a directory pointed to by <code>addResourcePath</code> breaks Shiny. If you're reading this, the <span id='test_passed'>test passed</span>!"),
  shinyjster::shinyjster_js("
    var jst = jster();
    jst.add(function() {
      Jster.assert.isEqual(
        $('#test_passed').text().trim(),
        'test passed'
      );
    });

    jst.test();
  ")
)

server <- function(input, output, session) {
  shinyjster::shinyjster_server(input, output, session)
}

shinyApp(ui, server)

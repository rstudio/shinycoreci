library(shiny)

ui <- fluidPage(
  "Below is a test for behavior described ",
  a("here", href = "https://github.com/rstudio/rmarkdown/pull/1631"),
  HTML("
  <p><code>runtime: shiny_prerendered</code> documents auto-magically register <a href='https://rmarkdown.rstudio.com/authoring_shiny_prerendered.html#external_resources'>css/js/images directories as shiny resource paths</a>. Thus, if you run a prerendered document, then run a shiny app that has, say a <code>www/js</code> directory, the previously registered <code>js</code> resource path is given higher precedence, which leads to wrong/suprising behavior (<code><a href='https://github.com/rstudio/shiny-examples/pull/153'>rstudio/shiny-examples#153</a></code> gives an example).</p>

  <p>This addresses the problem by using shiny's new <code>removeResourcePath()</code> (if available) to remove these resource paths once the next app finishes running. It seems like other calls to <code>shiny::addResourcePaths()<code> in rmarkdown should do something similar, but I'm not 100% sure that's the case, and those resource prefixes seem less likely to clash with other names anyway.</p>
"),
  br(),
  span(
    id = "test-message",
    style = "color: red",
    "Fail"
  ),
  tags$script(src = "js/run-test.js"),
  shinyjster::shinyjster_js("
    var jst = jster();
    jst.add(Jster.shiny.waitUntilStable);
    jst.add(function() {
      Jster.assert.isEqual(
        $('#test-message').text().trim(),
        'Pass'
      );
    });

    jst.test();
  ")
)

server <- function(input, output) {
  shinyjster::shinyjster_server(input, output)
}

shinyApp(ui, server)

library(shiny)

ui <- fluidPage(
  shinyjster::shinyjster_js("
    var jst = jster();
    jst.add(Jster.shiny.waitUntilStable);

    jst.add(function() {
      Jster.assert.isEqual(
        $('#text').text().trim(),
        'Pass'
      );
    });

    jst.test();
  "),

  titlePanel("Hello Shiny!"),
  p("This app has a trailing comma in the UI. Historically, that would have crashed the app. But as of htmltools `0.3.6.9004`, that's now allowed."),

   # NOTE THE TRAILING COMMA
  textOutput(outputId = "text"),
)

server <- function(input, output) {
  shinyjster::shinyjster_server(input, output)

  output$text <- renderText({
    "Pass"
  })
}

# Create Shiny app ----
shinyApp(ui = ui, server = server)

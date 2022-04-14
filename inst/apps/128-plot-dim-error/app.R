# Test for https://github.com/rstudio/shiny/issues/1964

library(shiny)

ui <- fluidPage(
  p("Verify that this app doesn't crash on startup, and that Go draws a plot."),
  actionButton("go", "Go"),
  plotOutput("plot"),
  shinyjster::shinyjster_js("
  var jst = jster();
  jst.add(Jster.shiny.waitUntilStable);

  jst.add(function() {
    Jster.button.click('go');
  })
  jst.add(Jster.shiny.waitUntilStable);

  jst.add(function() {
    Jster.assert.isTrue($('#plot img').length > 0, {length: $('#plot img').length});
    Jster.assert.isTrue(
      Jster.image.data('plot').length > 100, // 640000
      {
        type: 'image_data',
        length: Jster.image.data('plot').length
      }
    );
  });

  jst.test();
  ")
)

server <- function(input, output, session) {
  shinyjster::shinyjster_server(input, output, session)

  w <- eventReactive(input$go, { 400 })
  h <- eventReactive(input$go, { 400 })

  output$plot <- renderPlot({
    plot(cars)
  }, width = w, height = h)
}

shinyApp(ui, server)

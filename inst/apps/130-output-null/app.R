library(shiny)

ui <- fluidPage(
  h3("Pressing \"Clear\" should clear the plot."),
  plotOutput("plot"),
  actionButton("clear", "Clear"),

  shinyjster::shinyjster_js("
    var jst = jster();
    jst.add(function() { $('#clear').click(); });
    jst.add(Jster.shiny.waitUntilStable);
    jst.add(function() {
      Jster.assert.isTrue($('#plot').children().length == 0, {length: $('#plot').children().length, ele: $('#plot').html()})
    });
    jst.test();
    "
  )
)

server <- function(input, output, session) {
  shinyjster::shinyjster_server(input, output, session)

  output$plot <- renderPlot({ plot(cars) })

  observeEvent(input$clear, {
    output$plot <- NULL
  })
}

shinyApp(ui, server)

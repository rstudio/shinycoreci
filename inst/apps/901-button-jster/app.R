library(shiny)

ui <- fluidPage(

  titlePanel("Button Example - Do NOT Touch application"),

  sidebarLayout(

    sidebarPanel(
      actionButton("button", "Do not click me")
    ),

    mainPanel(
      verbatimTextOutput("number")
    )
  ),

  # include shinyjster JS at end of UI definition
  shinyjster::shinyjster_js("
    var jst = jster(500); // execute every 500 ms
    jst.add(function() { $('#button').click(); });
    jst.add(function() { $('#button').click(); });
    jst.add(function() { $('#button').click(); });
    jst.add(Jster.shiny.waitUntilIdle);
    jst.add(function() { Jster.assert.isEqual($('#number').text(), '3') });
    jst.test();
  ")

)

server <- function(input, output, session) {

  # include shinyjster_server call at top of server definition
  shinyjster::shinyjster_server(input, output, session)

  output$number <- renderText({
    input$button
  })
}

# Create Shiny app ----
shinyApp(ui = ui, server = server)

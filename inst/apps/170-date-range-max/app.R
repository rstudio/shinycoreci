library(shiny)
ui <- fluidPage(
  dateInput("val", "Date Input", max = Sys.Date()),
  "Below is a test for ",
  a("#2355", href = "https://github.com/rstudio/shiny/issues/2335"),
  verbatimTextOutput("res"),
  shinyjster::shinyjster_js("
    var jst = jster();
    jst.add(Jster.shiny.waitUntilStable);

    jst.add(function() {
      Jster.assert.isEqual(
        $('#res').text().trim(),
        'Pass'
      );
    });

    jst.test();
  ")
)
server <- function(input, output) {
  shinyjster::shinyjster_server(input, output)

  output$res <- renderText({
    if (length(input$val) > 0) "Pass" else "Fail"
  })
}
shinyApp(ui, server)

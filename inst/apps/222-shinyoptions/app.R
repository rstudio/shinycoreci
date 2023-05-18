library(shiny)
library(shinyjster)

my_ui <- function(id) {
  ns <- NS(id)
  verbatimTextOutput(ns("txt"), placeholder = TRUE)
}

my_server <- function(id, nested = FALSE) {
  moduleServer(id, function(input, output, session) {
    if (nested) {
      str(getCurrentOutputInfo())
      shinyOptions("my_option_nested" = "This is my_option_nested")
      output$txt <- renderText(getShinyOption("my_option_nested"))
    } else {
      shinyOptions("my_option" = "This is my_option")
      output$txt <- renderText(getShinyOption("my_option"))
    }
  })
}


my_ui_nested <- function(id) {
  ns <- NS(id)
  my_ui(ns(id))
}
my_server_nested <- function(id) {
  moduleServer(id, function(input, output, session) {
    my_server(id, TRUE)
  })
}

shinyApp(
  fluidPage(
    my_ui("one"),
    my_ui_nested("two"),
    shinyjster_js("
      var jst = jster();
      // Wait for renderUIs to complete
      jst.add(Jster.shiny.waitUntilIdleFor(1000));

      jst.add(function() { Jster.assert.isEqual($('#one-txt').text(), 'This is my_option') });
      jst.add(function() { Jster.assert.isEqual($('#two-two-txt').text(), 'This is my_option_nested') });

      jst.test();
    ")

  ),
  function(input, output, session) {
    shinyjster::shinyjster_server(input, output, session)
    my_server("one")
    my_server_nested("two")
  }
)

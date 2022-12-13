library(shiny)
library(bslib)
library(bsicons)

ui <- page_fluid(
  tags$style(".accordion {--bs-accordion-active-color: #dc3545; --bs-accordion-active-bg: rgba(220, 53, 69, 0.05)}"),
  accordion(
    id = "acc",
    accordion_item(
      title = "Test failed",
      icon = bs_icon("x-circle"),
      value = "test-message",
      "Try again"
    )
  ),
  shinyjster::shinyjster_js("
    var jst = jster(0);
    jst.add(Jster.shiny.waitUntilStable);
    jst.add(function() {
      Jster.assert.isEqual(
        $('#acc .accordion-button').text(), 'Test passed',
        'accordion_mutate() did not update the accordion()'
      );
    });
    jst.test();
  ")
)

server <- function(input, output, session) {

  shinyjster::shinyjster_server(input, output)

  observe({
    accordion_replace(
      id = "acc", target = "test-message",
      title = "Test passed",
      icon = bs_icon("check-circle"),
      "Nicely done!"
    )

    insertUI("body", ui = tags$style(".accordion {--bs-accordion-active-color: #198754; --bs-accordion-active-bg: rgba(25, 135, 84, 0.05) !important}"))
  })

}

shinyApp(ui, server)

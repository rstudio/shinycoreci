library(shiny)

ui <- fluidPage(
  includeScript("script.js"),
  p("This test exercises Shiny.setInputValue() with different priorities."),
  p("The word 'Pass' should appear below within a couple of seconds."),
  uiOutput("result"),
  shinyjster::shinyjster_js("
    var jst = jster();
    jst.add(Jster.shiny.waitUntilStable);

    jst.add(function(done) {
      var wait = function() {
        var txt = $('#result').text().trim();
        if (txt !== '') {
          done();
          return;
        }
        setTimeout(wait, 50);
      }
      wait();
    })

    jst.add(function() {
      Jster.assert.isEqual(
        $('#result').text().trim(),
        'Pass'
      );
    });

    jst.test();
  ")
)

server <- function(input, output, session) {
    shinyjster::shinyjster_server(input, output, session)

  test_evt_count <- reactiveVal(0)
  observeEvent(input$test_evt, {
    test_evt_count(test_evt_count() + 1)
  })

  test_val_count <- reactiveVal(0)
  observeEvent(input$test_val, {
    test_val_count(test_val_count() + 1)
  })

  o <- observeEvent(invalidateLater(2000), {
    o$destroy()
    output$result <- renderUI({
      if (identical(test_evt_count(), 5) && identical(test_val_count(), 1)) {
        tags$h1(class = "alert alert-success", "Pass")
      } else {
        tags$h1(class = "alert alert-danger", "fail")
        message("test_evt_count() == ", test_evt_count())
        message("test_val_count() == ", test_val_count())
      }
    })
  }, ignoreNULL = FALSE, ignoreInit = TRUE)
}

shinyApp(ui, server)

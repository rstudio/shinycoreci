library(shiny)
library(DT)

dtmod_ui <- function(id) {
  ns <- NS(id)

  tagList(
    DTOutput(ns("table")),
    p(),
    actionButton(ns("inc"), "Increment")
  )
}

dtmod <- function(input, output, session) {
  x <- reactiveVal(0L)

  output$table <- renderDT({
    DT::datatable(data.frame(value = isolate(x())), rownames = FALSE, options = list(dom = "t", ordering = FALSE))
  })

  observeEvent(input$inc, {
    x(x() + 1L)
  })

  observeEvent(x(), {
    replaceData(dataTableProxy("table"), x())
  })
}

ui <- fluidPage(
  h3("Test DT::replaceData with Shiny modules (rstudio/DT#626)"),
  p("Make sure each Increment button updates (only) the corresponding value"),
  fluidRow(
    column(3,
      h5("Non-module"),
      dtmod_ui(NULL)
    ),
    column(3,
      h5("Module"),
      dtmod_ui("one")
    )
  ),
  shinyjster::shinyjster_js("
    var jst = jster();
    jst.add(Jster.shiny.waitUntilStable);
    function validate(id, val) {
      Jster.assert.isEqual(
        $('#' + id + ' tbody').text() - 0,
        val
      )
    }
    function waitForVal(id, val) {
      return function(done) {
        var end = (new Date() - 0) + (10 * 1000);
        var wait = function() {
          var current = (new Date() - 0);
          if (current > end) {
            done();
          } else if (val == ($('#' + id + ' tbody').text() - 0)) {
            done();
          } else {
            setTimeout(wait, 100);
          }
        }
        wait();
      }
    }

    jst.add(function() {
      validate('table', 0);
      validate('one-table', 0);
    });

    jst.add(function() { Jster.button.click('inc'); });
    jst.add(function() { Jster.button.click('inc'); });
    jst.add(function() { Jster.button.click('inc'); });
    jst.add(function() { Jster.button.click('inc'); });

    jst.add(waitForVal('table', 4));

    jst.add(function() {
      validate('table', 4);
      validate('one-table', 0);
    })

    jst.add(function() { Jster.button.click('one-inc'); });
    jst.add(function() { Jster.button.click('one-inc'); });
    jst.add(function() { Jster.button.click('one-inc'); });
    jst.add(function() { Jster.button.click('one-inc'); });
    jst.add(function() { Jster.button.click('one-inc'); });
    jst.add(function() { Jster.button.click('one-inc'); });
    jst.add(function() { Jster.button.click('one-inc'); });

    jst.add(waitForVal('one-table', 7));

    jst.add(function() {
      validate('table', 4);
      validate('one-table', 7);
    });

    jst.add(function() { Jster.button.click('inc'); });
    jst.add(function() { Jster.button.click('inc'); });

    jst.add(waitForVal('table', 6));

    jst.add(function() {
      validate('table', 6);
      validate('one-table', 7);
    });

    jst.test();
  ")
)

server <- function(input, output, session) {
  shinyjster::shinyjster_server(input, output, session)

  # Call the module in an un-modular way
  dtmod(input, output, session)

  # Regular module invocation
  callModule(dtmod, "one")
}

shinyApp(ui, server)

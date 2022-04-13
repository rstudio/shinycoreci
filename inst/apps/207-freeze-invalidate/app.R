library(shiny)
library(shinyjster)

# This app contains two inputs, one of which is dependent on the other. There
# are two observers which look at both inputs; in order to pass, _the last time
# in a flush cycle_ that each observer executes, it should either see the two
# inputs in a consistent state OR attempt to read a frozen input and req(FALSE).

ui <- fluidPage(
  radioButtons("type", "Data type", c("numbers", "letters"), "numbers"),
  radioButtons("value", "Value", as.character(1:5), inline = TRUE),
  verbatimTextOutput("check"),
  shinyjster_js("
    var jst = jster();
    // Wait for renderUIs to complete
    jst.add(Jster.shiny.waitUntilIdleFor(1000));

    jst.add(function() { $('input[name=\"type\"][value=\"letters\"]').click(); });
    jst.add(Jster.shiny.waitUntilIdleFor(500));
    jst.add(function() { Jster.assert.isEqual($('#check').text(), 'OK') });

    jst.add(function() { $('input[name=\"type\"][value=\"numbers\"]').click(); });
    jst.add(Jster.shiny.waitUntilIdleFor(500));
    jst.add(function() { Jster.assert.isEqual($('#check').text(), 'OK') });

    jst.test();
  ")
)

server <- function(input, output, session) {
  shinyjster::shinyjster_server(input, output, session)

  ok_hi_pri <- reactiveVal(NULL)
  ok_lo_pri <- reactiveVal(NULL)
  ok_hi_pri_indirect <- reactiveVal(NULL)
  ok_lo_pri_indirect <- reactiveVal(NULL)

  choices <- reactive({
    switch(req(input$type),
      numbers = as.character(1:5),
      letters = letters[1:5],
      stop("Unexpected input$type value")
    )
  })

  obs_update <- observe({
    freezeReactiveValue(input, "value")
    updateRadioButtons(session, "value", choices = choices(), inline = TRUE)
  }, priority = 10)

  # consistent means e.g. "letters" and "a", inconsistent is like "letters" and
  # "1". One possibility is that input$value may throw due to it being frozen.
  is_data_consistent <- function() {
    if (isTRUE(input$value %in% choices())) {
      TRUE
    } else {
      FALSE
    }
  }

  r_value <- reactive({
    input$value
  })

  # Same as is_data_consistent, but go through a reactive expression instead of
  # accessing input$value directly.
  is_data_consistent_indirect <- function() {
    if (isTRUE(r_value() %in% choices())) {
      TRUE
    } else {
      FALSE
    }
  }

  consistency_test <- function(func, rxval) {
    # We're OK if the data is consistent, or if we touch something frozen
    tryCatch(
      rxval(func()),
      shiny.silent.error = function(e) {
        rxval(TRUE)
      }
    )
  }

  # We create two observers: one whose priority is higher than obs_update, and
  # one whose priority is lower.

  observe({
    consistency_test(is_data_consistent, ok_hi_pri)
  }, priority = 15)

  observe({
    consistency_test(is_data_consistent, ok_lo_pri)
  }, priority = 5)

  observe({
    consistency_test(is_data_consistent_indirect, ok_hi_pri_indirect)
  }, priority = 15)

  observe({
    consistency_test(is_data_consistent_indirect, ok_lo_pri_indirect)
  }, priority = 5)

  # For this test, even momentary failure signals that the test has failed. This
  # variable represents sort of the "high water mark" for how much output$check
  # has failed; once it has failed, we can't let it go back to "OK".
  failed <- NULL

  output$check <- renderText({
    results <- c(
      isTRUE(ok_hi_pri()),
      isTRUE(ok_lo_pri()),
      isTRUE(ok_hi_pri_indirect()),
      isTRUE(ok_lo_pri_indirect())
    )

    if (all(results)) {
      # Do nothing
    } else {
      failed <<- paste0("Fail (", paste0(collapse = ",", which(!results)), ")")
    }

    if (!is.null(failed)) {
      failed
    } else {
      "OK"
    }
  })
  # Beware of https://github.com/rstudio/shiny/issues/3057. I originally wrote
  # this using a negative priority for output$check, but due to that issue, only
  # priority = 0 can be used.
  outputOptions(output, "check", priority = 0)
}

shinyApp(ui, server)

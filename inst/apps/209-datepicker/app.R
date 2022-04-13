library(shiny)
library(magrittr)
library(rlang)

init_dates <- list(
  min = "2013-04-10",
  value = "2013-04-11",
  max = "2013-04-12"
)
reset_dates <- list(min = 10, value = 11, max = 12, possible = 10:12, txt = "Reset")

dates <- list(
  list(min = 13,   value = NULL, max = NULL, possible = NULL,  txt = "Set new min greater than old max"),
  reset_dates,
  list(min = 12,   value = NULL, max = NULL, possible = NULL,  txt = "Set new min greater than old value"),
  reset_dates,

  list(min = NULL, value = NULL, max = 9   , possible = NULL,  txt = "Set new max less than old min"),
  reset_dates,
  list(min = NULL, value = NULL, max = 10  , possible = NULL,  txt = "Set new max less than old value"),
  reset_dates,

  list(min = 12,   value = 13,   max = 14  , possible = 12:14, txt = "Set all going up, overlap"),
  reset_dates,
  list(min = 8,    value = 9,    max = 10  , possible = 8:10,  txt = "Set all going down, overlap"),
  reset_dates,

  list(min = 13,   value = 14,   max = 15  , possible = 13:15, txt = "Set all going up, no overlap"),
  reset_dates,
  list(min = 7,    value = 8,    max = 9   , possible = 7:9,   txt = "Set all going down, no overlap"),
  reset_dates


  # # Note: The cases where it unsets min, max, or value have yet to be
  # # implemented, so they're commented out for now.
  # list(min = none, value = NULL, max = NULL, txt = "Unset min"),
  # reset_dates,
  # list(min = NULL, value = NULL, max = none, txt = "Unset max"),
  # reset_dates,
  # list(min = NULL, value = none, max = NULL, txt = "Unset value"),
  # reset_dates
)




ui <- fluidPage(
  dateInput("date", "Example", min = init_dates$min, value = init_dates$value, max = init_dates$max),
  actionButton("go", "Go"),
  tags$table(
    tags$tr(tags$td("i:"), tags$td(verbatimTextOutput("i_val", TRUE))),
    tags$tr(tags$td("Action:"), tags$td(verbatimTextOutput("action", TRUE))),
    tags$tr(tags$td("Updated min:"), tags$td(verbatimTextOutput("up_min", TRUE))),
    tags$tr(tags$td("Updated value:"), tags$td(verbatimTextOutput("up_value", TRUE))),
    tags$tr(tags$td("Updated max:"), tags$td(verbatimTextOutput("up_max", TRUE))),
    tags$tr(tags$td("Expected possible dates:"), tags$td(verbatimTextOutput("possible", TRUE))),
    tags$tr(tags$td("input$date:"), tags$td(verbatimTextOutput("input_date", TRUE))),
  ),
  # include shinyjster JS at end of UI definition
  shinyjster::shinyjster_js("
    var jst = jster();

    var date_infos = ", jsonlite::toJSON(dates, auto_unbox = TRUE, null = "null"), ";

    date_infos.map(function(date_info, i) {
      jst.add(Jster.shiny.waitUntilStable);
      jst.add(function() {
        Jster.button.click('go');
      });
      jst.add(Jster.shiny.waitUntilStable);
      jst.add(function() {
        var i_val = $('#i_val').text().trim();
        var action = $('#action').text().trim();
        var input_date = $('#input_date').text().trim();

        Jster.assert.isEqual(i_val - 1, i, {i: i});
        Jster.assert.isEqual(action, date_info.txt, {i: i, date_info: date_info});
        if (date_info.value) {
          var date_value = '' + date_info.value;
          if (date_value.length == 1) date_value = '0' + date_value;
          Jster.assert.isEqual(input_date, '2013-04-' + date_value, {i: i, date_info: date_info, step: 'input_date'});
        } else {
          Jster.assert.isEqual(input_date, '');
        }

        Jster.datepicker.bs.show('date');
      })
      jst.add(function() {
        Jster.assert.isEqual(
          Jster.datepicker.possibleDates('date'),
          date_info.possible || []
        );
        Jster.datepicker.bs.hide('date');
      })
    });

    jst.test();
  ")
)

# Define server logic required to draw a histogram ----
server <- function(input, output, session) {

  # include shinyjster_server call at top of server definition
  shinyjster::shinyjster_server(input, output)

  # none <- character(0)

  date_objs <- lapply(dates, function(row) {
    lapply(row, function(val) {
      if (is.character(val))  val
      else if (!is.null(val)) sprintf("2013-04-%02d", val)
      else                    NULL
    })
  })

  i <- reactiveVal(0)
  observe({
    i(i() + 1)
    if (i() > length(dates)) {
      i(1)
    }

    updateDateInput(session, "date",
      min   = date_objs[[i()]]$min,
      value = date_objs[[i()]]$value,
      max   = date_objs[[i()]]$max
    )
  }) %>%
    bindEvent(input$go)

  output$i_val <- renderText({
    i()
  })
  output$input_date <- renderText({
    as.character(input$date)
  })

  render_date_text <- function(key) {
    renderText({
      if (i() > 0)
        dates[[i()]][[key]] %||% "NULL"
      else
        ""
    })
  }
  output$action   <- render_date_text("txt")
  output$up_min   <- render_date_text("min")
  output$up_value <- render_date_text("value")
  output$up_max   <- render_date_text("max")
  output$possible <- render_date_text("possible")
}

shinyApp(ui, server)

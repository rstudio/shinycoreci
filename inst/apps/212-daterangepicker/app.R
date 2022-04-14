library(shiny)

# DATA SET UP
# Initially setting the slider values from 6 to 10 to test with fewer dates
# Note: Later: Work with cases when the slider value is < 6 or > 25 with dynamic calendar dates.

init_data <- list(
  slider_min = 6,
  slider_value = 6,
  slider_max = 10
)

dates <- lapply(init_data$slider_min:init_data$slider_max, function(i){
  list(slider_val = i, possible_dates = (i-5):(i+5))
})

# UI LOGIC
ui <- fluidPage(
  sliderInput("n", "Day of month", init_data$slider_min, init_data$slider_max, init_data$slider_value),
  dateRangeInput("inDateRange", "Input date range"),

  tags$table(
    tags$tr(tags$td("Current slider value:"), tags$td(verbatimTextOutput("slider_val", TRUE))),
    tags$tr(tags$td("Updated from date:"), tags$td(verbatimTextOutput("up_from", TRUE))),
    tags$tr(tags$td("Updated to date:"), tags$td(verbatimTextOutput("up_to", TRUE))),
    tags$tr(tags$td("Expected possible dates:"), tags$td(verbatimTextOutput("possible", TRUE)))
  ),
  # include shinyjster JS at end of UI definition. This tests the updateDateRangePicker input tests.
  # When moving the slider, the start and end values should be the number -1 and +1, and the possible dates should be the number -5 and + 5
  shinyjster::shinyjster_js("
    var jst = jster(100)

    var date_infos = ", jsonlite::toJSON(dates, auto_unbox = TRUE, null = "null"), ";

    date_infos.map(function(date_info, i) {
      jst.add(Jster.shiny.waitUntilStable);

      jst.add(function() {
         //Jster.assert.isEqual(Jster.slider.getValue('n'), date_info.slider_val);
         Jster.slider.setValue('n', date_info.slider_val);
      });

      jst.add(Jster.shiny.waitUntilStable);
      jst.add(function() {
        var slider_val = $('#slider_val').text().trim() - 0; //convert string to number by adding 0
        var up_from = $('#up_from').text().trim() - 0;
        var up_to = $('#up_to').text().trim() - 0;

        // Verify from and to date values match accordingly with the slider value
        Jster.assert.isEqual(slider_val, date_info.slider_val, {slider_value: slider_val});
        Jster.assert.isEqual(up_from, date_info.slider_val - 1, {from: up_from});
        Jster.assert.isEqual(up_to, date_info.slider_val + 1, {to: up_to});

        // Verify from and to dates (yyyy-mm-dd format) in the date picker text box matches with the expected
        var from_date_value = '' + (date_info.slider_val - 1);
        if (from_date_value.length == 1) from_date_value = '0' + from_date_value;
        Jster.assert.isEqual(Jster.daterangepicker.from.value('inDateRange'), '2013-05-' + from_date_value)

        var to_date_value = '' + (date_info.slider_val + 1);
        if (to_date_value.length == 1) to_date_value = '0' + to_date_value;
        Jster.assert.isEqual(Jster.daterangepicker.to.value('inDateRange'), '2013-05-' + to_date_value)
      })

      // From Datepicker: Possible dates check
      jst.add(function() {
        Jster.daterangepicker.from.click('inDateRange');
      })
      jst.add(function() {
        var possible_values = $('#possible').text().trim();
        possible_values = JSON.parse(possible_values)

        console.log('Possible dates:' , Jster.datepicker.possibleDates('inDateRange'))
        Jster.assert.isEqual(
          Jster.datepicker.possibleDates('inDateRange'), date_info.possible_dates
        );
        Jster.daterangepicker.from.bs.hide('inDateRange');
      })

      // To Datepicker: Possible dates check
      jst.add(function() {
        Jster.daterangepicker.to.click('inDateRange');
      })
      jst.add(function() {
        var possible_values = $('#possible').text().trim();
        possible_values = JSON.parse(possible_values)

        console.log('Possible dates:' , Jster.datepicker.possibleDates('inDateRange'))
        Jster.assert.isEqual(
          Jster.datepicker.possibleDates('inDateRange'), date_info.possible_dates
        );
        Jster.daterangepicker.to.bs.hide('inDateRange');
      })

    })
    jst.test();
   ")
)

# SERVER LOGIC
server <- function(input, output, session) {

  # include shinyjster server call at top of server definition
  shinyjster::shinyjster_server(input, output)

  observe({
    date <- as.Date(paste0("2013-05-", input$n))

    updateDateRangeInput(session, "inDateRange",
                         label = "Date range picker",
                         start = date - 1,
                         end = date + 1,
                         min = date - 5,
                         max = date + 5
    )
  })

  #OUTPUTS
  output$slider_val <- renderText({
    input$n
  })

  output$up_from <- renderText({
    input$n-1
  })

  output$up_to <- renderText({
    input$n+1
  })

  output$possible <- renderText({
    start <- input$n-5
    end <- input$n+5
    possible <- start:end
    jsonlite::toJSON(possible)
  })


}

shinyApp(ui, server)

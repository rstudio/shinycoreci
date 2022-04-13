library(shiny)
library(magrittr)

ui <- fluidPage(
  fluidRow(
    column(12,
      h1("Throttle/debounce test app"),
      p("Click the button quickly. 'Unmetered' should update constantly. 'Throttle' should update every second. 'Debounce' should update only after you've stopped clicking for one second."),
      hr(),
      actionButton("click", "Increment")
    ),
    column(4,
      h3("Unmetered"),
      verbatimTextOutput("raw")
    ),
    column(4,
      h3("Throttle (1 second)"),
      verbatimTextOutput("throttle")
    ),
    column(4,
      h3("Debounce (1 second)"),
      verbatimTextOutput("debounce")
    )
  ),
  shinyjster::shinyjster_js("
    var jst = jster(0);
    jst.add(Jster.shiny.waitUntilStable);

    var click = function() {
      $('#click').click();
    }

    var base_vals = [0, 10, 20];
    base_vals.map(function(base_value) {
      var is_equal = function(id, val, clicks) {
        Jster.assert.isEqual(
          $('#' + id).text().trim() - base_value,
          val,
          {id: id, clicks: clicks}
        );
      }

      var equal_vals = function(raw_val, debounce_val) {
        var observed_raw = $('#raw').text().trim() - base_value;
        // make sure observed is never bigger than actual
        Jster.assert.isTrue(raw_val >= observed_raw, {raw_val: raw_val, observed_raw: observed_raw, context: 'raw >= observed', base_value: base_value});
        // make sure the gap is never bigger than 1
        Jster.assert.isTrue((raw_val - observed_raw) <= 1, {raw_val: raw_val, observed_raw: observed_raw, context: 'raw - observed <= 1', base_value: base_value});

        // is_equal('throttle', throttle_val, raw_val);
        var throttle_val = $('#throttle').text().trim() - base_value;
        Jster.assert.isTrue(throttle_val <= raw_val, {throttle_val: throttle_val, raw_val: raw_val, base_value: base_value})
        Jster.assert.isTrue(debounce_val <= throttle_val, {throttle_val: throttle_val, debounce_val: debounce_val, base_value: base_value})

        // is_equal('debounce', debounce_val, raw_val);
      }

      var err_found = undefined;
      jst.add(function(done) {

        equal_vals(0, 0);
        is_equal('throttle', 0, 0);

        var jst_setTimeout = function(fn, timeout) {
          setTimeout(
            function() {
              try {
                fn();
              } catch (e) {
                if (!err_found) {
                  err_found = e;
                }
                throw e;
              }
            },
            timeout
          );
        }

        jst_setTimeout(click, 0);
        jst_setTimeout(click, 250);
        jst_setTimeout(click, 500);
        jst_setTimeout(click, 750);
        jst_setTimeout(click, 1000);
        jst_setTimeout(click, 1250);
        jst_setTimeout(click, 1500);
        jst_setTimeout(click, 1750);
        jst_setTimeout(click, 2000);
        jst_setTimeout(click, 2250);

        jst_setTimeout(function() { equal_vals( 1,  0); },    0 + 125);
        jst_setTimeout(function() { equal_vals( 2,  0); },  250 + 125);
        jst_setTimeout(function() { equal_vals( 3,  0); },  500 + 125);
        jst_setTimeout(function() { equal_vals( 4,  0); },  750 + 125);
        jst_setTimeout(function() { equal_vals( 5,  0); }, 1000 + 125);
        jst_setTimeout(function() { equal_vals( 6,  0); }, 1250 + 125);
        jst_setTimeout(function() { equal_vals( 7,  0); }, 1500 + 125);
        jst_setTimeout(function() { equal_vals( 8,  1); }, 1750 + 125);
        jst_setTimeout(function() { equal_vals( 9,  2); }, 2000 + 125);
        jst_setTimeout(function() { equal_vals(10,  0); }, 2250 + 125);

        jst_setTimeout(function() {
          equal_vals(10, 10);
          is_equal('throttle', 10, 10);
        }, 5000);

        setTimeout(function() {
          done();
        }, 5500);
      });

      jst.add(function() {
        if (err_found) {
          throw err_found;
        }
      })
    });


    jst.test();
  ")
)

server <- function(input, output, session) {
  shinyjster::shinyjster_server(input, output, session)

  pos_raw <- reactive(input$click)
  pos_throttle <- pos_raw %>% throttle(1000)
  pos_debounce <- pos_raw %>% debounce(1000)

  output$raw <- renderText({
    pos_raw()
  })

  output$throttle <- renderText({
    pos_throttle()
  })

  output$debounce <- renderText({
    pos_debounce()
  })

}

shinyApp(ui, server)

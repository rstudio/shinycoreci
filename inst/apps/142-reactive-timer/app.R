library(shiny)

ui <- fluidPage(
  h2("reactiveTimer test"),
  p("This test exercises two reactiveTimers. One is global, one is per-session."),

  fluidRow(
    column(2, strong("Global:"), textOutput("global_counter", inline = TRUE)),
    column(2, strong("Session:"), textOutput("session_counter", inline = TRUE))
  ),

  h4(style = "margin-top: 40px", "Test 1"),
  p(
    "Ensure that the two numbers count upwards by one, both in the browser and in the console.",
    br(),
    "(It's OK if the counting is not perfectly synchronized.)"
  ),

  h4(style = "margin-top: 40px", "Test 2"),
  p("Push this button and ensure that the web and console counters pause for 5 seconds, then resume."),
  actionButton("busy_sync", "Be busy for 5 seconds (sync)"),

  h4(style = "margin-top: 40px", "Test 3"),
  p(
    "Push this button; both web counters should pause for 5 seconds, then jump ahead by 5. ",
    "The Global web counter will appear faded. ",
    "In the console, Glob should continue unabated, while Sess pauses for 5 seconds, then jumps ahead by 5."
  ),
  actionButton("busy_async", "Be busy for 5 seconds (async)"),

  shinyjster::shinyjster_js("
    var jst = jster(0);

    var get_global = function() {
      return $('#global_counter').text().trim() - 0;
    }
    var get_session = function() {
      return $('#session_counter').text().trim() - 0;
    }

    var infos = [
      {button: 'busy_sync', base_num: 3, increase: 0},
      {button: 'busy_async', base_num: 5, increase: 5},
      {button: 'busy_sync', base_num: 12, increase: 0},
      {button: 'busy_async', base_num: 15, increase: 5}
    ];
    infos.map(function(info) {
      var base_global = 0;
      var base_session = 0;
      var assert_is_kinda_equal = function(x, expected, id) {
        Jster.assert.isTrue(x <= expected + 1, {id: id, x: x, expected: expected, info: info})
        Jster.assert.isTrue(Math.abs(expected - x) <= 2, {id: id, x: x, expected: expected, tolerance: 2, info: info})
      }

      // wait until global counter is geq `info.base_num`
      jst.add(function(done) {
        var wait = function() {
          if (get_global() >= info.base_num) {
            done();
          } else {
            setTimeout(wait, 50);
          }
        }
        wait();
      })

      // capture current values
      jst.add(function() {
        base_global = get_global();
        base_session = get_session();

        Jster.button.click(info.button);
      });
      // wait 4 seconds and then wait until both values have changed
      jst.add(function(done) {
        var cur_global = get_global();
        var cur_session = get_session();
        var wait = function() {
          if (get_global() != cur_global) {
            if (get_session() != cur_session) {
              // global changed, session changed
              Jster.shiny.waitUntilStable(done);
            } else {
              // global changed, session NOT changed
              setTimeout(wait, 2);
            }
          } else {
            // global NOT changed
            setTimeout(wait, 50);
          }
        }
        setTimeout(wait, 4000);
      });

      // validate numbers are close.  Add 1 because we waited until number changed (increasing the value by 1)
      jst.add(function() {
        assert_is_kinda_equal(get_global(), base_global + info.increase + 1, 'global');
        assert_is_kinda_equal(get_session(), base_session + info.increase + 1, 'session');
      });

    });

    jst.test();
  ")
)

global_timer <- reactiveTimer(1000)

server <- function(input, output, session) {
  shinyjster::shinyjster_server(input, output)

  session_timer <- reactiveTimer(1000)

  global_counter_i <- 0L
  global_counter <- reactive({
    global_timer()
    on.exit(global_counter_i <<- global_counter_i + 1L)

    global_counter_i
  })

  session_counter_i <- 0L
  session_counter <- reactive({
    session_timer()
    on.exit(session_counter_i <<- session_counter_i + 1L)

    session_counter_i
  })

  output$global_counter <- renderText(global_counter())
  output$session_counter <- renderText(session_counter())

  observe({
    message("Glob: ", global_counter())
  })
  observe({
    message("Sess: ", session_counter())
  })

  observeEvent(input$busy_sync, {
    Sys.sleep(5)
  })

  observeEvent(input$busy_async, {
    promises::promise(~{later::later(~resolve(NULL), 5)})
  })
}

shinyApp(ui, server)

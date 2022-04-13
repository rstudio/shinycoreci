library(shiny)
library(future)
library(promises)
library(magrittr)
plan(multisession)

ui <- fluidPage(
  p("This app tests that ", tags$code("invalidateLater()"), " calls are held until async operations are complete."),
  tags$ol(
    tags$li("You should see the number below increasing by 1, every 2 seconds."),
    tags$li("The output should be semi-transparent (i.e. recalculating state) continuously."),
    tags$li("You should see the word 'Flushed' in the R console, every 2 seconds.")
  ),
  verbatimTextOutput("out"),
  verbatimTextOutput("out_flushed"),
  uiOutput("status"),
  shinyjster::shinyjster_js("
    var jst = jster();
    jst.add(function(done) {
      var wait = function() {
        if ($('#out').text() != '') {
          done();
        } else {
          setTimeout(wait, 100)
        }
      }
      wait();
    })
    jst.add(function(done) {
      // test that the number doesn't increase every 0.1 seconds, but ~2s
      startVal = parseInt($('#out').text(), 10);

      var assertValue = function(val) {
        var curVal = parseInt($('#out').text(), 10);
        var diff = Math.abs(curVal - val);
        console.log(curVal, val, diff);
        Jster.assert.isTrue(diff <= 1)
      }

      var arr = [0,1,2,3,4,5,6,7,8];
      arr.map(function(i, idx) {
        setTimeout(function() {
          if (i + startVal <= 10) {
            assertValue(i + startVal);
          }
          if ((idx + 1) == arr.length) {
            done();
          }
        }, i * 2 * 1000); // 2 second wait
      })
    });
    jst.add(function(done) {
      var wait = function() {
        if ($('#status').text().trim() == 'Waiting...') {
          setTimeout(wait, 100);
        } else {
          done();
        }
      }
      wait()
    });
    jst.add(Jster.shiny.waitUntilIdle);
    jst.add(function() {
      Jster.assert.isEqual(
        $('#status').text().trim(),
        'Pass!'
      )
    })
    jst.test();
  ")
)

server <- function(input, output, session) {
  # include shinyjster_server call at top of server definition
  shinyjster::shinyjster_server(input, output, session)

  value <- reactiveVal(0L)
  n <- 10

  start <- Sys.time()
  status <- reactiveVal("wait")

  observe({
    if (isolate(value()) < n) {
      invalidateLater(100)
    } else {
      diff_time <- as.difftime(Sys.time() - start, units = "secs")
      if (diff_time > ((n - 1) * 2)) {
        isolate({status("pass")})
      } else {
        isolate({status("fail")})
      }
    }
    isolate({ value(value() + 1L) })
  })

  output$status <- renderUI({
    switch(status(),
      "wait" = tags$h4(tags$span("Waiting...", style = "background-color: #dddddd;")),
      "pass" = tags$h4(tags$span("Pass!", style = "background-color: #7be092;")),
      tags$h4(tags$span("Fail!", style = "background-color: #e68a8a;"))
    )
  })

  session$onFlushed(function() {
    message("Flushed")
  }, once = FALSE)

  output$out <- renderText({
    future(Sys.sleep(2)) %...>%
      { value() }
  })
}

shinyApp(ui, server)

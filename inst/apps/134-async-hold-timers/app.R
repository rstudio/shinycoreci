library(shiny)
library(promises)
library(later)

wait_seconds <- function(secs) {
  force(secs)
  promise(~{later::later(~resolve(TRUE), secs)})
}

ui <- fluidPage(
  h2("Verify timers don't run until async tasks are complete"),
  "If this app runs for about 10 seconds without killing the session, that's success!",
  uiOutput("status"),
  shinyjster::shinyjster_js(
    "
    var jst = jster();
    jst.add(function(done) {
      var wait = function() {
        console.log('wait', $('#status').text().trim(), $('#status').text().trim() != 'Pass!')
        if ($('#status').text().trim() != 'Pass!') {
          setTimeout(wait, 200);
        } else {
          done();
        }
      }
      wait();
    })
    jst.test();"
  )
)

server <- function(input, output, session) {
  # include shinyjster_server call at top of server definition
  shinyjster::shinyjster_server(input, output, session)

  timer <- reactiveTimer(500)

  in_task <- FALSE

  # determine if older than 10 secs
  start <- Sys.time()
  is_done <- function() {
    diff <- as.difftime(Sys.time() - start, units = "secs")
    return(diff > 10)
  }

  # visual status
  is_passing <- reactiveVal(FALSE)
  output$status <- renderUI({
    if (is_passing()) {
      tags$h4(tags$span("Pass!", style = "background-color: #7be092;"))
    } else {
      tags$h4(tags$span("Waiting...", style = "background-color: #dddddd;"))
    }
  })
  observe({
    timer()
    req(is_done())
    is_passing(TRUE)
  })


  observe({
    req(!is_passing())
    invalidateLater(500)

    if (in_task) {
      stop("invalidateLater fired while async observer was active!")
    }
  }, priority = 1)

  observe({
    req(!is_passing())
    timer()

    if (in_task) {
      stop("reactiveTimer fired while async observer was active!")
    }
  }, priority = 1)

  observe({
    req(!is_passing())
    timer()

    in_task <<- TRUE
    wait_seconds(3) %...>% {
      in_task <<- FALSE
    }
  })

}

shinyApp(ui, server)

library(shiny)
library(pryr)

# It's possible for this test to fail when reactlog is enabled
op <- options(shiny.reactlog = FALSE)
onStop(function() {
  options(op)
})

ui <- fluidPage(
  p("This application tests if", code("invalidateLater"),
    "causes significant memory leakage. (",
    a("#2555", href = "https://github.com/rstudio/shiny/pull/2555", .noWS = "outside"),
    ")"
  ),
  p("After five iterations it will print out whether it passed or failed."),
  plotOutput("hist1"),

  tags$table(
    tags$tr(tags$td("Iteration:"), tags$td(verbatimTextOutput("iteration"))),
    tags$tr(tags$td("Memory usage:"), tags$td(verbatimTextOutput("memory"))),
    tags$tr(tags$td("Increase:"), tags$td(verbatimTextOutput("increase"))),
    tags$tr(tags$td("Avg Status:"), tags$td(uiOutput("status")))
  ),
  shinyjster::shinyjster_js("
    var jst = jster(500);
    jst.add(function(done) {
      var wait = function() {
        var txt = $('#status').text().trim();
        if (txt === '') {
          setTimeout(wait, 50);
        } else {
          var iteration = $('#iteration').text().trim();
          if ((iteration - 0) > 40) {
            done();
          } else {
            setTimeout(wait, 50);
          }
        }
      }
      wait();
    });

    jst.add(function() {
      Jster.assert.isEqual(
        $('#status').text().trim(),
        'Pass'
      );
    })

    jst.test();
  ")
)

server <- function(input, output, session) {
  shinyjster::shinyjster_server(input, output)

  i <- 0
  last_mem <- mem_used()
  last_10 <- rep(0, 10)

  output$hist1 <- renderPlot({
    invalidateLater(500)
    plot(c(1:100))
  })

  info <- reactive({
    invalidateLater(500)
    cur_mem <- mem_used()
    on.exit({
      i <<- i + 1
      last_mem <<- cur_mem
    })
    increase <- cur_mem - last_mem
    last_10 <- c(last_10[-1], increase)

    list(
      i = i,
      cur_mem = cur_mem,
      increase = increase,
      last_10 = last_10
    )
  })

  output$iteration <- renderText({
    info()$i
  })
  output$memory <- renderText({
    info()$cur_mem
  })
  output$increase <- renderText({
    info()$increase
  })
  output$status <- renderUI({
    if (info()$i < 5) {
      return("");
    }

    # make sure 80% of the results are < 512
    if (quantile(info()$last_10, 0.8, type = 1) <= 512) {
      p(style = "color:green;", "Pass")
    } else {
      p(style = "color:red;", "Fail: Leaking too much memory!")
    }
  })

}

shinyApp(ui,server)

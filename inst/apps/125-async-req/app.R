library(shiny)
library(promises)
library(future)
plan(multisession)

ui <- fluidPage(
  tags$style(
    "td, th { border: 1px solid #AAA; padding: 6px; }"
  ),
  h1("Test req, req(cancelOutput=TRUE), and validate/need with async"),
  actionButton("boom", "SELF DESTRUCT", class = "btn-danger"),
  p(),
  withTags(
    table(
      tr(
        td(),
        th("sync"),
        th("async")
      ),
      tr(
        th("req"),
        td(textOutput("req")),
        td(textOutput("req_async"))
      ),
      tr(
        th("req(cancelOutput)"),
        td(textOutput("cancelOutput")),
        td(textOutput("cancelOutput_async"))
      ),
      tr(
        th("validate/need"),
        td(textOutput("validateNeed")),
        td(textOutput("validateNeed_async"))
      )
    )
  ),
  shinyjster::shinyjster_js("
    var jst = jster();
    jst.add(Jster.shiny.waitUntilStable);
    jst.add(function() {
      var assertEqual = function(id, txt) {
        Jster.assert.isEqual($('#' + id).text(), txt);
      }
      assertEqual('req', 'After self destruct, this text should disappear');
      assertEqual('cancelOutput', 'After self destruct, this text should remain');
      assertEqual('validateNeed', 'After self destruct, this text should be replaced by a grey validation message');

      assertEqual('req_async', 'After self destruct, this text should disappear');
      assertEqual('cancelOutput_async', 'After self destruct, this text should remain');
      assertEqual('validateNeed_async', 'After self destruct, this text should be replaced by a grey validation message');
    });
    jst.add(function() {
      $('#boom').click();
    })
    jst.add(Jster.shiny.waitUntilStable);
    jst.add(function() {
      var assertEqual = function(id, txt) {
        Jster.assert.isEqual($('#' + id).text(), txt);
      }
      assertEqual('req', '');
      assertEqual('cancelOutput', 'After self destruct, this text should remain');
      assertEqual('validateNeed', 'Self destructed');

      assertEqual('req_async', '');
      assertEqual('cancelOutput_async', 'After self destruct, this text should remain');
      assertEqual('validateNeed_async', 'Self destructed');
    });
    jst.test();
  ")
)

server <- function(input, output, session) {
  # include shinyjster_server call at top of server definition
  shinyjster::shinyjster_server(input, output, session)

  output$req <- renderText({
    req(!isTruthy(input$boom))
    "After self destruct, this text should disappear"
  })
  output$cancelOutput <- renderText({
    req(!isTruthy(input$boom), cancelOutput = TRUE)
    "After self destruct, this text should remain"
  })
  output$validateNeed <- renderText({
    validate(need(!isTruthy(input$boom), "Self destructed"))
    "After self destruct, this text should be replaced by a grey validation message"
  })

  p <- future({ Sys.sleep(1) })

  output$req_async <- renderText({
    p %...>% {req(!isTruthy(input$boom))} %...>%
    {"After self destruct, this text should disappear"}
  })
  output$cancelOutput_async <- renderText({
    p %...>% {req(!isTruthy(input$boom), cancelOutput = TRUE)} %...>%
    {"After self destruct, this text should remain"}
  })
  output$validateNeed_async <- renderText({
    p %...>% {validate(need(!isTruthy(input$boom), "Self destructed"))} %...>%
    {"After self destruct, this text should be replaced by a grey validation message"}
  })
}

shinyApp(ui, server)

library(shiny)
library(future)
library(promises)
plan(multiprocess)

ui <- fluidPage(
  h1("renderPrint tests"),
  p(HTML("The \"visible\" cells should say <code>[1] \"Hello\"</code>, and the \"invisible\" cells should be empty.")),
  tags$style(
    "#results_table td, #results_table th { padding: 3px; border: 1px solid #AAA; }"
  ),
  withTags(
    table(id = "results_table",
      tr(
        td(),
        th("Sync"),
        th("Async")
      ),
      tr(
        th("Visible"),
        td(textOutput("sync_visible", container = pre)),
        td(textOutput("async_visible", container = pre))
      ),
      tr(
        th("Invisible"),
        td(textOutput("sync_invisible", container = pre)),
        td(textOutput("async_invisible", container = pre))
      )
    )
  ),
  shinyjster::shinyjster_js("
    var jst = jster();
    jst.add(Jster.shiny.waitUntilIdle);
    jst.add(function() {
      var assertEqual = function(id, txt) {
        Jster.assert.isEqual(
          $('#' + id).text(),
          txt
        );
      }
      assertEqual('sync_visible', '[1] \"Hello\"');
      assertEqual('async_visible', '[1] \"Hello\"');
      assertEqual('sync_invisible', '');
      assertEqual('async_invisible', '');
    });
    jst.test();
  ")
)

server <- function(input, output, session) {
  # include shinyjster_server call at top of server definition
  shinyjster::shinyjster_server(input, output, session)

  output$sync_visible <- renderPrint({
    "Hello"
  })
  output$async_visible <- renderPrint({
    future({ "Hello" })
  })
  output$sync_invisible <- renderPrint({
    invisible("Hello")
  })
  output$async_invisible <- renderPrint({
    future({ "Hello" }) %...>% invisible()
  })
}

shinyApp(ui, server)

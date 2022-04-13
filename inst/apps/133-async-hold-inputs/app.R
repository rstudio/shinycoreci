### Keep this line to manually test this shiny application. Do not edit this line; shinycoreci::::is_manual_app


library(shiny)
library(promises)
library(later)


wait <- function(secs) {
  force(secs)
  promise(~{later::later(~resolve(TRUE), secs)})
}

ui <- fluidPage(
  h2("Verify inputs are not updated until async tasks are complete"),
  p(
    strong("Instructions:"),
    tags$ol(
      tags$li("Press Go button"),
      tags$li("Immediately change the radio button value"),
      tags$li(
        "After 3 seconds, Shiny will return output; verify that all letters printed are the same.",
        "(The letter used will be whatever letter was selected at the time Go was pressed.)"
      )
    )
  ),
  sidebarLayout(
    sidebarPanel(
      radioButtons("choice", "Choose one", letters[1:5]),
      actionButton("go", "Go")
    ),
    mainPanel(
      verbatimTextOutput("out"),
      shinyjster::shinyjster_js(
        "
        var jst = jster();
        jst.add(Jster.shiny.waitUntilStable);

        var choose_and_submit = function(val) {
          jst.add(function() {
            Jster.radio.clickOption('choice', val);
            Jster.button.click('go');
          })
        }
        choose_and_submit('b');
        choose_and_submit('c');

        var validate_output = function(expected) {
          jst.add(Jster.shiny.waitUntilStable);
          jst.add(function() {
            // make sure choice is expected
            Jster.assert.isEqual(Jster.radio.currentOption('choice'), expected);
            // make sure all output is made of _expected_
            var unique_vals = $.unique($('#out').text().trim().split('\\n').map(function(item) {return item.trim()}))
            Jster.assert.isEqual(unique_vals.length, 1);
            Jster.assert.isEqual(unique_vals[0], expected);
          })
        }
        jst.wait(2 * 3 * 1000);
        validate_output('c');

        choose_and_submit('b');
        choose_and_submit('c');
        choose_and_submit('b');
        choose_and_submit('b');
        choose_and_submit('c');
        choose_and_submit('b');
        choose_and_submit('b');
        choose_and_submit('c');
        choose_and_submit('e');

        jst.wait(9 * 3 * 1000);
        validate_output('e');

        jst.test();"
      )
    )
  )
)

server <- function(input, output, session) {
  # include shinyjster_server call at top of server definition
  shinyjster::shinyjster_server(input, output, session)

  output$out <- renderPrint({
    req(input$go)

    prog <- Progress$new(session)
    prog$set(message = "Thinking...")
    isolate({
      cat(input$choice, "\n")
      wait(1) %...>% {
        cat(input$choice, "\n")
        wait(1)
      } %...>% {
        cat(input$choice, "\n")
        wait(1)
      } %...>% {
        cat(input$choice, "\n")
      } %>% finally(~prog$close()) %...>% {
        invisible()
      }
    })
  })
}

shinyApp(ui, server)

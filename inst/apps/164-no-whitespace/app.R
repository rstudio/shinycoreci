library(shiny)

# Define UI for app
ui <- fluidPage(
  # App title ----
  titlePanel("Suppress Whitespace!"),
  shiny::textOutput("package"),
  tags$hr(),
  tags$div(id="first", "This should contain whitespace inside the single quotes (default behavior): '", tags$a(href="https://shiny.rstudio.com", "Shiny"), "'."),
  tags$div(id="firstOutcome", class="alert alert-info"),
  tags$hr(),
  tags$div(id="second", "This should NOT contain whitespace inside the single quotes:  '", tags$a(href="https://shiny.rstudio.com", "Shiny", .noWS="outside"), "'."),
  tags$div(id="secondOutcome", class="alert alert-info"),
  tags$hr(),
  helpText("The first link above doesn't specify a `.noWS` argument, so spacing is added around the link which isn't the ideal presentation since we want to enquote it. The second link sets `.noWS=\"outside\"` to squash the whitespace around the link."),
  tags$script("
// Validation
function isValid(inputId, noWhitespaceExpected) {
  return /'Shiny'/.test($('#' + inputId).text()) === noWhitespaceExpected
}
// Some JavaScript to help automate testing
function testWhitespace(inputId, outputId, noWhitespaceExpected) {
  var output = $('#' + outputId);

  if (isValid(inputId, noWhitespaceExpected)) {
    output.text('Pass!');
  } else {
    output.text('FAIL');
  }
}
testWhitespace('first', 'firstOutcome', false);
testWhitespace('second', 'secondOutcome', true);
"),
  shinyjster::shinyjster_js("
    var jst = jster();
    jst.add(Jster.shiny.waitUntilStable);

    jst.add(function() {
      Jster.assert.isTrue(
        isValid('first', false)
      );
      Jster.assert.isTrue(
        isValid('second', true)
      );
    });

    jst.test();
  ")
)

# Define server logic required to draw a histogram ----
server <- function(input, output, session) {
  shinyjster::shinyjster_server(input, output, session)
}

# Create Shiny app ----
shinyApp(ui = ui, server = server)

library(shiny)

# Regression test for https://github.com/rstudio/shiny/pull/2524/
choices <- factor(setNames(letters, LETTERS))

ui <- fluidPage(
  title = "Select from Factor",
  tags$ol(
    tags$li("Select any capital letter from the input below."),
    tags$li("You should see your selection reflected, in lower case, in the output area.")
  ),
  selectInput("letter", "Letters", choices = choices),
  tags$h3("Output"),
  verbatimTextOutput("selected"),
  shinyjster::shinyjster_js("
    var jst = jster(50);

    var alpha = 'abcdefghijklmnopqrstuvwxyz';
    var lowerLetters = alpha.split('');
    var upperLetters = alpha.toUpperCase().split('');

    jst.add(Jster.shiny.waitUntilStable);
    jst.add(function() {
      Jster.selectize.click('letter');
    });
    jst.add(Jster.shiny.waitUntilIdle);
    jst.add(function() {
      var values = Jster.selectize.values('letter');
      Jster.assert.isEqual(values.length, 26, {values: values});

      values.map(function(val, i) {
        Jster.assert.isEqual(val.value, lowerLetters[i]);
        Jster.assert.isEqual(val.label, upperLetters[i]);
      });

      Jster.selectize.clickOption('letter', 0);
    });


    [].concat(lowerLetters)
      .sort(function(){ return Math.random() - 0.5 })
      .map(function(letter, i) {

        jst.add(Jster.shiny.waitUntilIdle);
        jst.add(function() {
          Jster.selectize.click('letter');
        });
        jst.add(Jster.shiny.waitUntilIdle);
        jst.add(function() {
          Jster.selectize.clickOption('letter', lowerLetters.indexOf(letter));
        });
        jst.add(Jster.shiny.waitUntilIdle);
        jst.add(function() {
          Jster.assert.isEqual(
            $('#selected').text().trim(),
            'You selected: ' + letter
          );
        });
      })

    jst.test();
  ")
)

server <- function(input, output, session) {
  shinyjster::shinyjster_server(input, output, session)

  output$selected <- renderText({
    sprintf("You selected: %s", input$letter)
  })
}


shinyApp(ui, server)

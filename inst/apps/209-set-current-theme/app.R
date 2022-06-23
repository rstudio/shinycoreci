library(shiny)
library(bslib)
light <- bs_theme()
dark <- bs_theme(bg = "black", fg = "white")
ui <- fluidPage(
  theme = light,
  checkboxInput("dark_mode", "Dark mode", value = FALSE),
  verbatimTextOutput("bg"),
  verbatimTextOutput("fg"),
  shinyjster::shinyjster_js("
    var jst = jster();
    jst.add(Jster.shiny.waitUntilStable);
    jst.add(Jster.shiny.waitUntilIdleFor(1000));

    jst.add(function() {
      var bg = window.getComputedStyle(document.body).backgroundColor;
      var white = 'rgb(255, 255, 255)';
      Jster.assert.isEqual(bg === 'transparent' ? white : bg, white);
    });

    jst.add(function() {
      Shiny.setInputValue('dark_mode', true);
    });

    jst.add(Jster.shiny.waitUntilStable);
    jst.add(Jster.shiny.waitUntilIdleFor(1000));

    // Wait until the body's bg color has changed
    jst.add(function(done) {
      var wait = function() {
        var bg = window.getComputedStyle(document.body).backgroundColor;
        if (bg === 'rgb(255, 255, 255)') {
          setTimeout(wait, 100);
          return;
        }
        done();
        return;
      }
      wait();
    });


    jst.add(function() {
      var bg = window.getComputedStyle(document.body).backgroundColor;
      Jster.assert.isEqual(bg, 'rgb(0, 0, 0)');
      // Make sure getCurrentTheme() has been invalidated
      Jster.assert.isEqual(
        $('#bg').text().trim(), '#000000'
      );
      Jster.assert.isEqual(
        $('#fg').text().trim(), '#FFFFFF'
      );
    });

    jst.test();
  ")
)
server <- function(input, output, session) {
  shinyjster::shinyjster_server(input, output)

  observe(session$setCurrentTheme(
    if (isTRUE(input$dark_mode)) dark else light
  ))

  get_theme_vals <- function(vars) {
    vals <- bs_get_variables(session$getCurrentTheme(), vars)
    htmltools::parseCssColors(unname(vals))
  }

  output$bg <- renderText(get_theme_vals("bg"))
  output$fg <- renderText(get_theme_vals("fg"))
}
shinyApp(ui, server)


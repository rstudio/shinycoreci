library(shiny)
library(leaflet)

ui <- fluidPage(
  tags$script(HTML(
    "window.leaflet_calls = [];"
  )),
  p("This app checks whether htmlwidgets can be loaded if the htmlwidgets dependency isn't part of the initial page load. ",
    "See ",
    a(href = "https://github.com/ramnathv/htmlwidgets/issues/349", "htmlwidgets#349"),
    " for more details."
  ),
  p("The following should happen:"),
  tags$ol(
    tags$li("'onRender' called"),
    tags$li("'onStaticRender' called"),
    tags$li("The map appears, with markers (and no background tiles)."),
  ),
  p("You should see a status of `Pass` below the map."),
  uiOutput("ui"),
  uiOutput("status"),
  shinyjster::shinyjster_js("
    var jst = jster();
    jst.add(function(done) {
      var wait = function() {
        var txt = $('#status').text().trim();
        if (txt.length > 0) {
          setTimeout(done); // wait for any more events to possibly load
          return;
        }
        setTimeout(wait, 50);
      }
      wait();
    });
    jst.add(Jster.shiny.waitUntilStable);

    jst.add(function() {
      Jster.assert.isEqual(
        $('#status').text().trim(),
        'Pass'
      );
    });

    jst.test();
  ")
)

server <- function(input, output, session) {
  shinyjster::shinyjster_server(input, output)

  output$ui <- renderUI({
    tagList(
      leaflet(quakes) %>%
        # addTiles() %>% # do not add tiles for CI purposes
        addMarkers(~ long, ~ lat) %>%
        htmlwidgets::onRender("function(el, x) {
          console.log('onRender called');
          window.leaflet_calls.push('onRender');
        }"),
      htmlwidgets::onStaticRenderComplete("
        console.log('onStaticRender called');
        window.leaflet_calls.push('onStaticRender');
        Shiny.setInputValue('status_vals', window.leaflet_calls);
      ")
    )
  })

  output$status <- renderUI({
    vals <- input$status_vals
    if (length(vals) == 0) {
      return(NULL)
    }
    if (length(vals) < 2) {
      return(p(style="color:red;", "FAIL: not enough events called. ", paste0(vals, collapse = ", ")))
    }
    if (identical(vals, c("onRender", "onStaticRender"))) {
      return(p(style="color:green;", "Pass"))
    }
    return(p(style="color:red;", "FAIL: unknown vals: ", paste0(vals, collapse = ", ")))
  })

}

shinyApp(ui, server)

## Note: This app is VERY similar to the app 217-snapshot-info-description. If you change something here, please update it there.

library(shiny)

if (shinycoreci::platform() == "win") {
  # Windows does not like UTF-8
  items <- c("aa", "bb", "AA", "BB", "a_", "b_", "_A", "_B")
  items_expected <- c("AA", "BB", "_A", "_B", "a_", "aa", "b_", "bb")
} else {
  items <- c("aa", "bb", "åå", "∫∫", "AA", "BB", "a_", "b_", "_A", "_B")
  items_expected <- c("AA", "BB", "_A", "_B", "a_", "aa", "b_", "bb", "åå", "∫∫")
  # sort(items, method = "radix")
  # #> [1] "AA" "BB" "_A" "_B" "a_" "aa" "b_" "bb" "åå" "∫∫"
  # sort(items, method = "shell")
  # #> [1] "_A" "_B" "∫∫" "a_" "aa" "AA" "åå" "b_" "bb" "BB"
}

uiItems <- lapply(items, function(item) {
  textOutput(item, inline = TRUE)
})
inputItems <- lapply(items, function(item) {
  radioButtons(item, paste0("input$", item), paste0(item, "_value"), inline = TRUE)
})

ui <- fluidPage(
  p("This app tests whether the local snapshot calculation respects the url query parameter `sortC=1` to sort according to the ", code("C")," locale"),
  p("Original issue: ", a(href="https://github.com/rstudio/shinytest/issues/409", "https://github.com/rstudio/shinytest/issues/409#issuecomment-930498442")),
  p("PR: ", a(href="https://github.com/rstudio/shiny/pull/3515", "https://github.com/rstudio/shiny/pull/3515")),
  p("To run the application: ", code('shiny::runApp("apps/217-snapshot-info-url/", test.mode = TRUE)')),
  hr(),

  strong("Status"), textOutput("status", inline = TRUE),br(),
  strong(
    "Link to visit: ", a(id = "link")
  ),br(),
  tags$script(HTML(paste0("
    $(function() {
      var counter = 0;
      var wait = function() {
        try {
          console.log('Counter: ', counter)
          var url = Shiny.shinyapp.getTestSnapshotBaseUrl({full: true}) + '&input=", paste0(items, collapse = ","), "&output=", paste0(items, collapse = ","), "&format=json&sortC=1';
          $('#link').text(url);
          $('#link').attr('href', url);
          Shiny.setInputValue('url', url);
          var items = ", jsonlite::toJSON(items), ";
          items.map(function(item) {
            Shiny.setInputValue(item, item + '_value');
          });
          Shiny.setInputValue('url', url);
          $.get(url, function(data) {
            console.log('Data: ', data);
            Shiny.setInputValue('lines', JSON.stringify(data, null, '  '));
            Shiny.setInputValue('content', data);
          })
        } catch (e) {
          console.log('Error: ', e);
          if (counter < 100) {
            counter++;
            setTimeout(wait, 100);
          }
        }
      }
      wait()
    });
  "))),
  "Items: ", uiItems, br(),
  "Lines: ", verbatimTextOutput("lines"),
)
server <- function(input, output, session) {
  lapply(items, function(item) {
    output[[item]] <- renderText({item})
  })

  output$time <- renderPrint({
    Sys.time()
  })

  output$lines <- renderPrint({
    req(input$lines)
    cat(input$lines, "\n")
  })

  is_match <- reactive({
    content <- input$content
    req(content)

    identical(names(content$input), items_expected) &&
    identical(names(content$output), items_expected)
  })
  output$status <- renderText({
    if (is_match()) {
      "PASS"
    } else {
      paste0("FAIL: Names do not match: ", paste0(items_expected, collapse = "\n"))
    }
  })
 }

shinyApp(ui, server)

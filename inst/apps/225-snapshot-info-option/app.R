## Note: This app is VERY similar to the app 217-snapshot-info-url. If you change something here, please update it there.

library(shiny)

shinyOptions(snapshotsortc = TRUE)

if (.Platform$OS.type == "windows") {
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
  p("This app tests whether the local snapshot calculation respects the ", code("shinyOptions(snapshotsortc = TRUE)"), " option when the url query parameter `sortC=1` is not present."),
  p("Original issue: ", a(href="https://github.com/rstudio/shinytest/issues/409", "https://github.com/rstudio/shinytest/issues/409#issuecomment-930498442")),
  p("PR: ", a(href="https://github.com/rstudio/shiny/pull/3515", "https://github.com/rstudio/shiny/pull/3515")),
  p("To run the application: ", code('shiny::runApp("apps/217-snapshot-info-option/", test.mode = TRUE)')),
  hr(),

  strong("Status"), textOutput("status", inline = TRUE),br(),
  strong(
    "Link to visit: ", a(id = "link")
  ),br(),
  tags$script(HTML(paste0("
    $(function() {
      window.snapshotRequestedAfterServerAck = false;
      var items = ", jsonlite::toJSON(items), ";

      Shiny.addCustomMessageHandler('snapshot-ready', function(message) {
        var url = Shiny.shinyapp.getTestSnapshotBaseUrl({full: true}) + '&input=", paste0(items, collapse = ","), "&output=", paste0(items, collapse = ","), "&format=json';
        $('#link').text(url);
        $('#link').attr('href', url);
        Shiny.setInputValue('url', url);
        window.snapshotRequestedAfterServerAck = true;

        $.get(url, function(data) {
          console.log('Data: ', data);
          Shiny.setInputValue('lines', JSON.stringify(data, null, '  '));
          Shiny.setInputValue('content', data);
        });
      });

      var sendInputs = function() {
        items.map(function(item) {
          Shiny.setInputValue(item, item + '_value');
        });
        Shiny.setInputValue('snapshot_ready_request', true);
      };

      if (typeof Shiny.setInputValue === 'function') {
        sendInputs();
      } else {
        $(document).one('shiny:connected', sendInputs);
      }
    });
  "))),
  "Items: ", uiItems, br(),
  "Lines: ", verbatimTextOutput("lines"),
)
server <- function(input, output, session) {
  lapply(items, function(item) {
    output[[item]] <- renderText({item})
  })

  observeEvent(input$snapshot_ready_request, {
    expected_values <- paste0(items, "_value")
    actual_values <- unname(vapply(items, function(item) input[[item]], character(1)))
    req(identical(actual_values, expected_values))

    session$onFlushed(function() {
      session$sendCustomMessage("snapshot-ready", list())
    }, once = TRUE)
  }, once = TRUE)

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
      paste(
        "FAIL: Names do not match",
        paste0("Expected: ", paste(items_expected, collapse = ", ")),
        paste0("Actual input: ", paste(names(input$content$input), collapse = ", ")),
        paste0("Actual output: ", paste(names(input$content$output), collapse = ", ")),
        sep = "\n"
      )
    }
  })
 }

shinyApp(ui, server)

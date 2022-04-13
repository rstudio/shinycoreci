library(shiny)
library(shinyjster)

ui <- function(req) {
  if (req[["PATH_INFO"]] == "/") {
    list(
      includeScript("app.js"),
      tags$img(id = "logo", src = "image.jpg"),
      shinyjster_js("
        var jst = jster();

        // Test if logo loaded properly
        jst.add(function() { Jster.assert.isEqual($('#logo').width(), 100); });
        jst.add(function() { Jster.assert.isEqual($('#logo').height(), 76); });

        // Test if POST request can be made successfully
        jst.add(verifyPOST);
        
        jst.test();
      ")

    )
  } else if (req[["PATH_INFO"]] == "/image.jpg") {
    path <- file.path(R.home("doc"), "html", "logo.jpg")
    httpResponse(
      status = 200L,
      content_type = "image/jpg",
      content = readBin(path, what = raw(0), n = file.info(path)$size)
    )
  } else if (req[["PATH_INFO"]] == "/post_endpoint") {
    httpResponse(
      status = 200L,
      content_type = "text/plain",
      content = "All good!"
    )
  } else {
    NULL
  }
}

attr(ui, "http_methods_supported") <- c("GET", "POST")

server <- function(input, output, session) {
  shinyjster::shinyjster_server(input, output, session)
}

shinyApp(ui, server, uiPattern = ".*")


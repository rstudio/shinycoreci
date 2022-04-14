library(shiny)
library(promises)
library(future)
plan(multisession)


make_row <- function(func, base_id, label, ...) {
  tagList(
    fluidRow(
      column(12, hr())
    ),
    fluidRow(
      column(2,
        h4(label)
      ),
      column(5,
        func(base_id, ...)
      ),
      column(5,
        func(paste0(base_id, "a"), ...)
      )
    ),
    br()
  )
}

ui <- fluidPage(
  tags$p(
    tags$strong("Instructions:"),
    "Verify that each row contains two identical outputs."
  ),
  fluidRow(
    column(2),
    column(5, h2("Sync")),
    column(5, h2("Async"))
  ),
  make_row(plotOutput, "plot", "Plot"),
  make_row(textOutput, "text", "Text"),
  make_row(verbatimTextOutput, "print", "Print"),
  make_row(verbatimTextOutput, "print2", "Print 2"),
  make_row(dataTableOutput, "datatable", "Data Table"),
  make_row(imageOutput, "image", "Image", height = "auto"),
  make_row(tableOutput, "table", "Table"),
  make_row(uiOutput, "ui", "UI"),
  shinyjster::shinyjster_js("
    var jst = jster();
    jst.add(Jster.shiny.waitUntilStable);
    jst.add(function(done) {
      var wait = function() {

        if ($('#DataTables_Table_0_processing').css('display') != 'none') {
          setTimeout(wait, 20);
          return;
        }
        if ($('#DataTables_Table_1_processing').css('display') != 'none') {
          setTimeout(wait, 20);
          return;
        }
        done();
      }
      wait();
    })
    jst.add(function() {
      var assertEqual = function(id) {
        console.log('id: ', id);
        var sync = $('#' + id).get(0).innerHTML;
        var async = $('#' + id + 'a').get(0).innerHTML
        if (id == 'datatable') {
          // replace 'known' non-matching strings
          sync = sync.replace(  /_Table([s]{0,1})_(0|1)/g, '_Table$1_k')
          async = async.replace(/_Table([s]{0,1})_(0|1)/g, '_Table$1_k')
        }
        Jster.assert.isEqual(sync, async);
      }
      var ids = [
        'plot',
        'text',
        'print',
        'print2',
        'datatable',
        'image',
        'table',
        'ui'
      ]
      ids.map(assertEqual);
    });
    jst.test();
  ")
)

server <- function(input, output, session) {

  # include shinyjster_server call at top of server definition
  shinyjster::shinyjster_server(input, output, session)

  output$plot <- renderPlot({
    plot(cars)
  })

  output$plota <- renderPlot({
    future({ Sys.sleep(1) }) %...>% {
      plot(cars)
    }
  })

  output$text <- renderText({
    "hello"
  })

  output$texta <- renderText({
    future({ Sys.sleep(1); "hello" })
  })

  output$print <- renderPrint({
    print("hello")
  })

  output$printa <- renderPrint({
    future({ Sys.sleep(1) }) %...>% { print("hello") }
  })

  output$print2 <- renderPrint({
    "hello"
  })

  output$print2a <- renderPrint({
    future({ Sys.sleep(1) }) %...>% { "hello" }
  })

  output$datatable <- renderDataTable({
    head(cars)
  })

  output$datatablea <- renderDataTable({
    future({ Sys.sleep(1); head(cars) })
  })

  output$image <- renderImage({
    path <- tempfile(fileext = ".gif")
    download.file("https://www.google.com/images/logo.gif", path, mode = "wb")
    list(src = path)
  }, deleteFile = TRUE)

  output$imagea <- renderImage({
    future({
      path <- tempfile(fileext = ".gif")
      download.file("https://www.google.com/images/logo.gif", path, mode = "wb")
      path
    }) %...>% {
      list(src = .)
    }
  }, deleteFile = TRUE)

  output$table <- renderTable({
    head(cars)
  })

  output$tablea <- renderTable({
    future({ Sys.sleep(1); head(cars) })
  })

  output$ui <- renderUI({
    h1("hello world")
  })

  output$uia <- renderUI({
    future({ Sys.sleep(1); h1("hello world") })
  })

}

shinyApp(ui, server)

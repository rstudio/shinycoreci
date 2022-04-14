library(shiny)
library(shinymeta)
library(plotly)
library(DT)

# Needed to display the modal
library(shinyAce)
library(clipr)

selectColumnUI <- function(id, label) {
  ns <- NS(id)
  tagList(
    varSelectInput(ns("col"), label, NULL),
    textOutput(ns("average"))
  )
}

selectColumn <- function(input, output, session, df) {
  observeEvent(df(), {
    updateVarSelectInput(session, "col", data = df())
  })

  values <- metaReactive2({
    req(input$col)
    metaExpr({
      ..(df()) %>%
        dplyr::pull(!!..(input$col))
    })
  })

  avg <- metaReactive({
    ..(values()) %>%
      mean() %>%
      round(1)
  })

  output$average <- metaRender(renderText, {
    paste("Average of", ..(as.character(input$col)), "is", ..(avg()))
  })

  list(
    values = values,
    average = output$average
  )
}

ui <- fluidPage(
  fluidRow(
    column(3, selectColumnUI("x", "x var")),
    column(3, selectColumnUI("y", "y var"))
  ),
  outputCodeButton(plotOutput("plot")),
  outputCodeButton(plotlyOutput("plotly")),
  outputCodeButton(dataTableOutput("table")),
  shinyjster::shinyjster_js(paste(collapse = "\n", readLines("shinyjster.js")))
)

server <- function(input, output, session) {
  # include shinyjster_server call at top of server definition
  shinyjster::shinyjster_server(input, output)

  dataset <- metaReactive({mtcars})

  x <- callModule(selectColumn, "x", dataset)
  y <- callModule(selectColumn, "y", dataset)

  df_plot <- metaReactive({
    "# Combine x and y into data frame for plotting"
    data.frame(x = ..(x$values()), y = ..(y$values()))
  })

  output$plot <- metaRender(renderPlot, {
    plot(..(df_plot()))
  })

  observeEvent(input$plot_output_code, {
    displayCodeModal(expandChain(
      output$plot(),
      x$average(),
      y$average()
    ))
  })

  output$plotly <- metaRender(renderPlotly, {
    plot_ly(..(df_plot()), x = ~x, y = ~y) %>%
      add_markers()
  })

  observeEvent(input$plotly_output_code, {
    displayCodeModal(expandChain(
      output$plotly(),
      x$average(),
      y$average()
    ))
  })

  output$table <- metaRender(renderDataTable, {
    datatable(..(df_plot()))
  })

  observeEvent(input$table_output_code, {
    displayCodeModal(expandChain(
      output$table(),
      x$average(),
      y$average()
    ))
  })
}

shinyApp(ui, server)

library(shiny)
library(rlang)
library(DiagrammeR)


inlineCodeOutput <- function(id) {
  tags$code(textOutput(id, inline = TRUE), .noWS = "inside")
}

old_par <- par(mar = rep(0.1, 4))
# on.exit({par(old_par)})

shinyApp(
  ui = fluidPage(
    tags$head(
      tags$style(HTML("
        table td, table th {
          padding: 5px;
        }
        .shiny-plot-output {
          min-height: 250px;
          min-width: 250px;
        }
      "))
    ),
    tags$h3(tags$code("shiny::installExprFunction(rlang::quo(x), quoted = TRUE)")),
    tags$p(
      "Init PR allowing quosures to", tags$code("exprToFunction()"), "and",
      tags$code("installExprFunction()"), "with increased usage of",
      tags$code("installExprFunction()"), "within Shiny: ",
      tags$a("https://github.com/rstudio/shiny/pull/3472", href = "https://github.com/rstudio/shiny/pull/3472")
    ),
    actionButton("n", "Click Me!"),
    tags$br(),
    fluidRow(
      tags$table(
        tags$thead(
          tags$tr(
            tags$th(),
            tags$th(tags$code("reactive()"), "-", inlineCodeOutput("reactive__expected")),
            tags$th(tags$code("renderText()"), "-", inlineCodeOutput("text__expected")),
            tags$th(tags$code("renderPrint()"), "-", inlineCodeOutput("print__expected")),
            tags$th(tags$code("observe()"), "-", inlineCodeOutput("observe__expected")),
            tags$th(tags$code("observeEvent()"), "-", inlineCodeOutput("observe_event__expected")),
            tags$th(tags$code("eventReactive()"), "-", inlineCodeOutput("event__expected")),
          )
        ),
        tags$tbody(
          tags$tr(
            tags$td("manual"),
            tags$td(verbatimTextOutput("reactive__manual", placeholder = TRUE)),
            tags$td(verbatimTextOutput("text__manual", placeholder = TRUE)),
            tags$td(verbatimTextOutput("print__manual", placeholder = TRUE)),
            tags$td(verbatimTextOutput("observe__manual", placeholder = TRUE)),
            tags$td(verbatimTextOutput("observe_event__manual", placeholder = TRUE)),
            tags$td(verbatimTextOutput("event_reactive__manual", placeholder = TRUE)),
          ),
          tags$tr(
            tags$td("quoted"),
            tags$td(verbatimTextOutput("reactive__quoted", placeholder = TRUE)),
            tags$td(verbatimTextOutput("text__quoted", placeholder = TRUE)),
            tags$td(verbatimTextOutput("print__quoted", placeholder = TRUE)),
            tags$td(verbatimTextOutput("observe__quoted", placeholder = TRUE)),
            tags$td(verbatimTextOutput("observe_event__quoted", placeholder = TRUE)),
            tags$td(verbatimTextOutput("event_reactive__quoted", placeholder = TRUE)),
          ),
          tags$tr(
            tags$td("injected"),
            tags$td(verbatimTextOutput("reactive__injected", placeholder = TRUE)),
            tags$td(verbatimTextOutput("text__injected", placeholder = TRUE)),
            tags$td(verbatimTextOutput("print__injected", placeholder = TRUE)),
            tags$td(verbatimTextOutput("observe__injected", placeholder = TRUE)),
            tags$td(verbatimTextOutput("observe_event__injected", placeholder = TRUE)),
            tags$td(verbatimTextOutput("event_reactive__injected", placeholder = TRUE)),
          )
        )
      )
    ),
    tags$hr(),
    fluidRow(
      tags$table(
        tags$thead(
          tags$tr(
            tags$th(),
            tags$th("External", tags$code("htmlwidgets"), "- Point to letter: ", inlineCodeOutput("render__expected")),
            tags$th(tags$code("renderTable()"), "-", inlineCodeOutput("table__expected"), "rows"),
            tags$th(tags$code("renderImage()"), "-", inlineCodeOutput("image__expected"), ""),
            tags$th(tags$code("renderPlot()"), "- Plot of", inlineCodeOutput("plot__expected"))
          )
        ),
        tags$tbody(
          tags$tr(
            tags$td("manual"),
            tags$td(DiagrammeROutput("render__manual")),
            tags$td(tableOutput("table__manual")),
            tags$td(imageOutput("image__manual", height = 150)),
            tags$td(plotOutput("plot__manual", height = 250)),
          ),
          tags$tr(
            tags$td("quoted"),
            tags$td(DiagrammeROutput("render__quoted")),
            tags$td(tableOutput("table__quoted")),
            tags$td(imageOutput("image__quoted", height = 150)),
            tags$td(plotOutput("plot__quoted", height = 250)),
          ),
          tags$tr(
            tags$td("injected"),
            tags$td(DiagrammeROutput("render__injected")),
            tags$td(tableOutput("table__injected")),
            tags$td(imageOutput("image__injected", height = 150)),
            tags$td(plotOutput("plot__injected", height = 250)),
          )
        )
      )
    )
  ),
  server = function(input, output) {

    dia_quo <- local({
      txt <- function(x) {
        paste0("
        graph LR
          A-->B
          A-->C
          C-->E
          B-->D
          C-->D
          D-->F[", letters[x %% length(letters)], "]
          E-->F
      ")
      }
      quo({
        DiagrammeR(txt(input$n + 6))
      })
    })

    r_quo <- local({
      a <- 10
      quo(as.numeric(a + input$n))
    })

    make_event_quo <- function() {
      a <- 1
      quo({
        input$n + a
      })
    }
    make_counter <- 0
    make_clicks_rv_and_quo <- function() {
      make_counter <<- make_counter + 1
      observe_rv <- reactiveVal(NULL)
      observe_quo <- local({
        txt <- paste0(make_counter, " - Clicks: ")
        quo({
          observe_rv(
            paste0(txt, input$n)
          )
        })
      })
      list(rv = observe_rv, quo = observe_quo)
    }
    make_value_quo <- function() {
      make_counter <<- make_counter + 1
      txt <- paste0(make_counter, " - Clicks: ")
      quo({
        paste0(txt, input$n)
      })
    }

    plot_quo <- local({
      k <- 5
      quo({
        n <- input$n + k
        x <- 1:n
        y <- 1:n
        plot(x, y)
      })
    })

    table_quo <- local({
      k <- 3
      quo({
        head(cars, input$n %% 3 + k)
      })
    })

    image_quo <- local({
      face <- "images/face.png"
      bear <- "images/bear.png"
      quo({
        if (input$n %% 2 == 0) {
          list(
            src = bear,
            height = "150px",
            width = "150px",
            contentType = "image/png",
            alt = "Deadlift"
          )
        } else {
          list(
            src = face,
            height = "150px",
            width = "150px",
            contentType = "image/png",
            alt = "Face"
          )
        }
      })
    })

    r_manual <- reactive(quo_get_expr(r_quo), env = quo_get_env(r_quo), quoted = TRUE)
    r_quoted <- reactive(r_quo, quoted = TRUE)
    r_injected <- inject(reactive(!!r_quo))
    output$reactive__expected <- renderText({input$n + 10})
    output$reactive__manual <- renderText({ r_manual() })
    output$reactive__quoted <- renderText({ r_quoted() })
    output$reactive__injected <- renderText({ r_injected() })

    output$text__expected <- renderText({input$n + 10})
    output$text__manual <- renderText(quo_get_expr(r_quo), env = quo_get_env(r_quo), quoted = TRUE)
    output$text__quoted <- renderText(r_quo, quoted = TRUE)
    output$text__injected <- inject(renderText(!!r_quo))

    output$print__expected <- renderPrint({as.numeric(input$n + 10)})
    output$print__manual <- renderPrint(quo_get_expr(r_quo), env = quo_get_env(r_quo), quoted = TRUE)
    output$print__quoted <- renderPrint(r_quo, quoted = TRUE)
    output$print__injected <- inject(renderPrint(!!r_quo))

    output$render__expected <- renderText(letters[(input$n + 6) %% length(letters)])
    output$render__manual <- renderDiagrammeR(quo_get_expr(dia_quo), env = quo_get_env(dia_quo), quoted = TRUE)
    output$render__quoted <- renderDiagrammeR(dia_quo, quoted = TRUE)
    output$render__injected <- inject(renderDiagrammeR(!!dia_quo))

    output$plot__expected <- renderText(paste0("1:", input$n + 5))
    output$plot__manual <- renderPlot(quo_get_expr(plot_quo), env = quo_get_env(plot_quo), quoted = TRUE)
    output$plot__quoted <- renderPlot(plot_quo, quoted = TRUE)
    output$plot__injected <- inject(renderPlot(!!plot_quo))

    output$table__expected <- renderText(input$n %% 3 + 3)
    output$table__manual <- renderTable(quo_get_expr(table_quo), env = quo_get_env(table_quo), quoted = TRUE)
    output$table__quoted <- renderTable(table_quo, quoted = TRUE)
    output$table__injected <- inject(renderTable(!!table_quo))

    ex_quo <- quo({
      paste0("Clicks: ", input$n)
    })
    output$observe__expected <- renderText(ex_quo, quoted = TRUE)
    output$observe_event__expected <- renderText(ex_quo, quoted = TRUE)
    output$event__expected <- renderText(ex_quo, quoted = TRUE)


    observeManual <- make_clicks_rv_and_quo()
    observe(quo_get_expr(observeManual$quo), env = quo_get_env(observeManual$quo), quoted = TRUE)
    output$observe__manual <- renderText(observeManual$rv())

    observeQuoted <- make_clicks_rv_and_quo()
    observe(observeQuoted$quo, quoted = TRUE)
    output$observe__quoted <- renderText(observeQuoted$rv())

    observeInjected <- make_clicks_rv_and_quo()
    rlang::inject(observe(!!observeInjected$quo))
    output$observe__injected <- renderText(observeInjected$rv())


    oeEventQuo <- make_event_quo()
    oeHandlerManual <- make_clicks_rv_and_quo()
    observeEvent(
      eventExpr = quo_get_expr(oeEventQuo), event.env = quo_get_env(oeEventQuo), event.quoted = TRUE,
      handlerExpr = quo_get_expr(oeHandlerManual$quo), handler.env = quo_get_env(oeHandlerManual$quo), handler.quoted = TRUE
    )
    output$observe_event__manual <- renderText(oeHandlerManual$rv())

    oeHandlerQuoted <- make_clicks_rv_and_quo()
    observeEvent(
      eventExpr = oeEventQuo, event.quoted = TRUE,
      handlerExpr = oeHandlerQuoted$quo, handler.quoted = TRUE
    )
    output$observe_event__quoted <- renderText(oeHandlerQuoted$rv())

    oeHandlerInjected <- make_clicks_rv_and_quo()
    inject(observeEvent(
      eventExpr = !!oeEventQuo,
      handlerExpr = !!oeHandlerInjected$quo
    ))
    output$observe_event__injected <- renderText(oeHandlerInjected$rv())


    erManualQuo <- make_value_quo()
    erManualRv <- eventReactive(
      eventExpr = quo_get_expr(oeEventQuo), event.env = quo_get_env(oeEventQuo), event.quoted = TRUE,
      valueExpr = quo_get_expr(erManualQuo), value.env = quo_get_env(erManualQuo), value.quoted = TRUE
    )
    output$event_reactive__manual <- renderText(erManualRv())

    erQuotedQuo <- make_value_quo()
    erQuotedRv <- eventReactive(
      eventExpr = oeEventQuo, event.quoted = TRUE,
      valueExpr = erQuotedQuo, value.quoted = TRUE
    )
    output$event_reactive__quoted <- renderText(erQuotedRv())

    erInjectedQuo <- make_value_quo()
    erInjectedRv <- inject(eventReactive(
      eventExpr = !!oeEventQuo,
      valueExpr = !!erInjectedQuo
    ))
    output$event_reactive__injected <- renderText(erInjectedRv())


    output$image__expected <- renderText({
      if (input$n %% 2 == 0) {
        "bear lifting"
      } else {
        "shocked face"
      }
    })
    output$image__manual <- renderImage(quo_get_expr(image_quo), env = quo_get_env(image_quo), quoted = TRUE, deleteFile = FALSE)
    output$image__quoted <- renderImage(image_quo, quoted = TRUE, deleteFile = FALSE)
    output$image__injected <- inject(renderImage(!!image_quo, deleteFile = FALSE))

  }
)

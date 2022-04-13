### Keep this line to manually test this shiny application. Do not edit this line; shinycoreci::::is_manual_app

library(shiny)
library(shinyjster)
library(magrittr)

table <- tags$table
th <- tags$th
tr <- tags$tr
td <- tags$td


ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      table, th, td {
        border: 1px solid #ddd;
        padding: 3px;
      }
    "))
  ),
  markdown("This app tests `bindCache()` and `bindEvent()` with `reactive()` and `renderText()`."),
  sliderInput("n", "n", 100, 110, 105),
  actionButton("go", "Go"),
  table(

    tr(
      th("Code"),
      th("Value"),
      th("Exec count")
    ),
    tr(
      td(code("reactive() %>% bindCache()")),
      td(textOutput("r_c_txt")),
      td(textOutput("r_c_count_txt"))
    ),
    tr(
      td(code("reactive() %>% bindEvent()")),
      td(textOutput("r_e_txt")),
      td(textOutput("r_e_count_txt"))
    ),
    tr(
      td(code("reactive() %>% bindCache() %>% bindEvent()")),
      td(textOutput("r_ce_txt")),
      td(textOutput("r_ce_count_txt"))
    ),
    tr(
      td(code("renderText() %>% bindCache()")),
      td(textOutput("rt_c_txt")),
      td(textOutput("rt_c_count_txt"))
    ),
    tr(
      td(code("renderText() %>% bindEvent()")),
      td(textOutput("rt_e_txt")),
      td(textOutput("rt_e_count_txt"))
    ),
    tr(
      td(code("renderText() %>% bindCache() %>% bindEvent()")),
      td(textOutput("rt_ce_txt")),
      td(textOutput("rt_ce_count_txt"))
    ),
  ),
  shinyjster_js("
    var jst = jster();
    jst.add(Jster.shiny.waitUntilStable);

    jst.add(function() { Jster.assert.isEqual($('#r_c_txt').text(),   '105') });
    jst.add(function() { Jster.assert.isEqual($('#r_e_txt').text(),   ''   ) });
    jst.add(function() { Jster.assert.isEqual($('#r_ce_txt').text(),  ''   ) });
    jst.add(function() { Jster.assert.isEqual($('#rt_c_txt').text(),  '105') });
    jst.add(function() { Jster.assert.isEqual($('#rt_e_txt').text(),  ''   ) });
    jst.add(function() { Jster.assert.isEqual($('#rt_ce_txt').text(), ''   ) });

    jst.add(function() { Jster.assert.isEqual($('#r_c_count_txt').text(),   '1') });
    jst.add(function() { Jster.assert.isEqual($('#r_e_count_txt').text(),   '0') });
    jst.add(function() { Jster.assert.isEqual($('#r_ce_count_txt').text(),  '0') });
    jst.add(function() { Jster.assert.isEqual($('#rt_c_count_txt').text(),  '1') });
    jst.add(function() { Jster.assert.isEqual($('#rt_e_count_txt').text(),  '0') });
    jst.add(function() { Jster.assert.isEqual($('#rt_ce_count_txt').text(), '0') });


    jst.add(function() { $('#go').click(); });
    jst.add(Jster.shiny.waitUntilStable);

    jst.add(function() { Jster.assert.isEqual($('#r_c_txt').text(),   '105') });
    jst.add(function() { Jster.assert.isEqual($('#r_e_txt').text(),   '105') });
    jst.add(function() { Jster.assert.isEqual($('#r_ce_txt').text(),  '105') });
    jst.add(function() { Jster.assert.isEqual($('#rt_c_txt').text(),  '105') });
    jst.add(function() { Jster.assert.isEqual($('#rt_e_txt').text(),  '105') });
    jst.add(function() { Jster.assert.isEqual($('#rt_ce_txt').text(), '105') });

    jst.add(function() { Jster.assert.isEqual($('#r_c_count_txt').text(),   '1') });
    jst.add(function() { Jster.assert.isEqual($('#r_e_count_txt').text(),   '1') });
    jst.add(function() { Jster.assert.isEqual($('#r_ce_count_txt').text(),  '1') });
    jst.add(function() { Jster.assert.isEqual($('#rt_c_count_txt').text(),  '1') });
    jst.add(function() { Jster.assert.isEqual($('#rt_e_count_txt').text(),  '1') });
    jst.add(function() { Jster.assert.isEqual($('#rt_ce_count_txt').text(), '1') });


    jst.add(function() { Jster.slider.setValue('n', 110); });
    jst.add(Jster.shiny.waitUntilStable);

    jst.add(function() { Jster.assert.isEqual($('#r_c_txt').text(),   '110') });
    jst.add(function() { Jster.assert.isEqual($('#r_e_txt').text(),   '105') });
    jst.add(function() { Jster.assert.isEqual($('#r_ce_txt').text(),  '105') });
    jst.add(function() { Jster.assert.isEqual($('#rt_c_txt').text(),  '110') });
    jst.add(function() { Jster.assert.isEqual($('#rt_e_txt').text(),  '105') });
    jst.add(function() { Jster.assert.isEqual($('#rt_ce_txt').text(), '105') });

    jst.add(function() { Jster.assert.isEqual($('#r_c_count_txt').text(),   '2') });
    jst.add(function() { Jster.assert.isEqual($('#r_e_count_txt').text(),   '1') });
    jst.add(function() { Jster.assert.isEqual($('#r_ce_count_txt').text(),  '1') });
    jst.add(function() { Jster.assert.isEqual($('#rt_c_count_txt').text(),  '2') });
    jst.add(function() { Jster.assert.isEqual($('#rt_e_count_txt').text(),  '1') });
    jst.add(function() { Jster.assert.isEqual($('#rt_ce_count_txt').text(), '1') });


    jst.add(function() { $('#go').click(); });
    jst.add(Jster.shiny.waitUntilStable);

    jst.add(function() { Jster.assert.isEqual($('#r_c_txt').text(),   '110') });
    jst.add(function() { Jster.assert.isEqual($('#r_e_txt').text(),   '110') });
    jst.add(function() { Jster.assert.isEqual($('#r_ce_txt').text(),  '110') });
    jst.add(function() { Jster.assert.isEqual($('#rt_c_txt').text(),  '110') });
    jst.add(function() { Jster.assert.isEqual($('#rt_e_txt').text(),  '110') });
    jst.add(function() { Jster.assert.isEqual($('#rt_ce_txt').text(), '110') });

    jst.add(function() { Jster.assert.isEqual($('#r_c_count_txt').text(),   '2') });
    jst.add(function() { Jster.assert.isEqual($('#r_e_count_txt').text(),   '2') });
    jst.add(function() { Jster.assert.isEqual($('#r_ce_count_txt').text(),  '2') });
    jst.add(function() { Jster.assert.isEqual($('#rt_c_count_txt').text(),  '2') });
    jst.add(function() { Jster.assert.isEqual($('#rt_e_count_txt').text(),  '2') });
    jst.add(function() { Jster.assert.isEqual($('#rt_ce_count_txt').text(), '2') });


    jst.add(function() { Jster.slider.setValue('n', 105); });
    jst.add(Jster.shiny.waitUntilStable);

    jst.add(function() { Jster.assert.isEqual($('#r_c_txt').text(),   '105') });
    jst.add(function() { Jster.assert.isEqual($('#r_e_txt').text(),   '110') });
    jst.add(function() { Jster.assert.isEqual($('#r_ce_txt').text(),  '110') });
    jst.add(function() { Jster.assert.isEqual($('#rt_c_txt').text(),  '105') });
    jst.add(function() { Jster.assert.isEqual($('#rt_e_txt').text(),  '110') });
    jst.add(function() { Jster.assert.isEqual($('#rt_ce_txt').text(), '110') });

    jst.add(function() { Jster.assert.isEqual($('#r_c_count_txt').text(),   '2') });
    jst.add(function() { Jster.assert.isEqual($('#r_e_count_txt').text(),   '2') });
    jst.add(function() { Jster.assert.isEqual($('#r_ce_count_txt').text(),  '2') });
    jst.add(function() { Jster.assert.isEqual($('#rt_c_count_txt').text(),  '2') });
    jst.add(function() { Jster.assert.isEqual($('#rt_e_count_txt').text(),  '2') });
    jst.add(function() { Jster.assert.isEqual($('#rt_ce_count_txt').text(), '2') });


    jst.add(function() { $('#go').click(); });
    jst.add(Jster.shiny.waitUntilStable);

    jst.add(function() { Jster.assert.isEqual($('#r_c_txt').text(),   '105') });
    jst.add(function() { Jster.assert.isEqual($('#r_e_txt').text(),   '105') });
    jst.add(function() { Jster.assert.isEqual($('#r_ce_txt').text(),  '105') });
    jst.add(function() { Jster.assert.isEqual($('#rt_c_txt').text(),  '105') });
    jst.add(function() { Jster.assert.isEqual($('#rt_e_txt').text(),  '105') });
    jst.add(function() { Jster.assert.isEqual($('#rt_ce_txt').text(), '105') });

    jst.add(function() { Jster.assert.isEqual($('#r_c_count_txt').text(),   '2') });
    jst.add(function() { Jster.assert.isEqual($('#r_e_count_txt').text(),   '3') });
    jst.add(function() { Jster.assert.isEqual($('#r_ce_count_txt').text(),  '2') });
    jst.add(function() { Jster.assert.isEqual($('#rt_c_count_txt').text(),  '2') });
    jst.add(function() { Jster.assert.isEqual($('#rt_e_count_txt').text(),  '3') });
    jst.add(function() { Jster.assert.isEqual($('#rt_ce_count_txt').text(), '2') });

    jst.test();
  ")
)

server <- function(input, output, session) {
  # include shinyjster_server call at top of server definition
  shinyjster::shinyjster_server(input, output)

  r_c_count  <- reactiveVal(0)
  r_e_count  <- reactiveVal(0)
  r_ce_count <- reactiveVal(0)

  r_c <- reactive({
      r_c_count(r_c_count() + 1)
      input$n
    }) %>%
    bindCache(input$n, cache = "session")
  output$r_c_txt <- renderText(r_c())

  r_e <- reactive({
      r_e_count(r_e_count() + 1)
      input$n
    }) %>%
    bindEvent(input$go)
  output$r_e_txt <- renderText(r_e())

  r_ce <- reactive({
      r_ce_count(r_ce_count() + 1)
      input$n
    }) %>%
    bindCache(input$n, cache = "session") %>%
    bindEvent(input$go)
  output$r_ce_txt <- renderText(r_ce())

  output$r_c_count_txt  <- renderText(r_c_count())
  output$r_e_count_txt  <- renderText(r_e_count())
  output$r_ce_count_txt <- renderText(r_ce_count())


  rt_c_count  <- reactiveVal(0)
  rt_e_count  <- reactiveVal(0)
  rt_ce_count <- reactiveVal(0)
  output$rt_c_txt <- renderText({
      rt_c_count(rt_c_count() + 1)
      input$n
    }) %>%
    bindCache(input$n, cache = "session")
  output$rt_e_txt <- renderText({
      rt_e_count(rt_e_count() + 1)
      input$n
    }) %>%
    bindEvent(input$go)
  output$rt_ce_txt <- renderText({
      rt_ce_count(rt_ce_count() + 1)
      input$n
    }) %>%
    bindCache(input$n, cache = "session") %>%
    bindEvent(input$go)

  output$rt_c_count_txt  <- renderText(rt_c_count())
  output$rt_e_count_txt  <- renderText(rt_e_count())
  output$rt_ce_count_txt <- renderText(rt_ce_count())
}

shinyApp(ui, server)

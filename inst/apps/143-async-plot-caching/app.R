library(shiny)
library(promises)
library(ggplot2)

ui <- fluidPage(
  h1("Caching async plots/keys"),
  p("Ensure that all eight plots appear."),
  hr(),
  fluidRow(
    column(6,
      h4("Sync base plot, sync cache key"),
      plotOutput("plotNN")
    ),
    column(6,
      h4("Async base plot, sync cache key"),
      plotOutput("plotYN")
    )
  ),
  fluidRow(
    column(6,
      h4("Sync base plot, Async cache key"),
      plotOutput("plotNY")
    ),
    column(6,
      h4("Async base plot, async cache key"),
      plotOutput("plotYY")
    )
  ),
  fluidRow(
    column(6,
      h4("Sync ggplot, sync cache key"),
      plotOutput("ggplotNN")
    ),
    column(6,
      h4("Async ggplot, sync cache key"),
      plotOutput("ggplotYN")
    )
  ),
  fluidRow(
    column(6,
      h4("Sync ggplot, Async cache key"),
      plotOutput("ggplotNY")
    ),
    column(6,
      h4("Async ggplot, async cache key"),
      plotOutput("ggplotYY")
    )
  ),
  shinyjster::shinyjster_js(
    "var jst = jster();",
    "jst.add(Jster.shiny.waitUntilIdle);",
    paste0(
      collapse = "\n",
      lapply(
        list(
          c("plotNN", "plotYN"),
          c("plotNY", "plotYY"),
          c("ggplotNN", "ggplotYN"),
          c("ggplotNN", "ggplotYN")
        ),
        function(id_pair) {
          sync_id <- id_pair[1]
          async_id <- id_pair[2]

          paste0(
            "
            jst.add(function() {
              var syncSrc = $('#", sync_id, "').attr('src');
              var asyncSrc = $('#", async_id, "').attr('src');
              Jster.assert.isEqual(syncSrc, asyncSrc);
            });
            "
          )
        }
      )
    ),
    "jst.test();"
  )

)

server <- function(input, output, session) {
  # include shinyjster_server call at top of server definition
  shinyjster::shinyjster_server(input, output, session)

  syncPlot <- function() {
    plot(cars)
  }
  asyncPlot <- function() {
    promise_resolve(TRUE) %...>% {
      syncPlot()
    }
  }
  ggsyncPlot <- function() {
    ggplot(cars, aes(speed, dist)) + geom_point()
  }
  ggasyncPlot <- function() {
    promise_resolve(TRUE) %...>% {
      ggsyncPlot()
    }
  }
  syncKey <- function() {
    Sys.time()
  }
  asyncKey <- function() {
    promise_resolve(syncKey())
  }

  output$plotNN <- renderCachedPlot({
    syncPlot()
  }, cacheKeyExpr = syncKey())

  output$plotYN <- renderCachedPlot({
    asyncPlot()
  }, cacheKeyExpr = syncKey())

  output$plotNY <- renderCachedPlot({
    syncPlot()
  }, cacheKeyExpr = asyncKey())

  output$plotYY <- renderCachedPlot({
    asyncPlot()
  }, cacheKeyExpr = asyncKey())

  output$ggplotNN <- renderCachedPlot({
    ggsyncPlot()
  }, cacheKeyExpr = syncKey())

  output$ggplotYN <- renderCachedPlot({
    ggasyncPlot()
  }, cacheKeyExpr = syncKey())

  output$ggplotNY <- renderCachedPlot({
    ggsyncPlot()
  }, cacheKeyExpr = asyncKey())

  output$ggplotYY <- renderCachedPlot({
    ggasyncPlot()
  }, cacheKeyExpr = asyncKey())
}

shinyApp(ui, server)

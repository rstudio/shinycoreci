### Keep this line to manually test this shiny application. Do not edit this line; shinycoreci::::is_manual_app

library(shiny)
library(ggplot2)
library(dplyr)

m <- mpg %>%
  select(fl, cty, drv) %>%
  distinct(cty, drv, .keep_all = TRUE) %>%
  mutate(key = dplyr::row_number())

ui <- basicPage(
  p("Brushing these plots should return the correct number of data points"),
  p(
    a("Issue #1433", href = "https://github.com/rstudio/shiny/issues/1433"), "/",
    a("PR #2410", href = "https://github.com/rstudio/shiny/pull/2410")
  ),
  plotOutput("plot1", brush = "brush1"),
  uiOutput("res1"),
  br(),
  plotOutput("plot2", brush = "brush2"),
  uiOutput("res2"),
  plotOutput("plot3", brush = "brush3"),
  uiOutput("res3")
)

server <- function(input, output) {

  output$plot1 <- renderPlot({
    ggplot(m) +
      geom_point(aes(fl, cty)) +
      facet_wrap(~drv, scales = "free_x") +
      geom_rect(
        data = data.frame(
          x1 = 0.8,
          x2 = 1.2,
          y1 = 28,
          y2 = 36,
          drv = "f"
        ),
        aes(xmin=x1, xmax=x2, ymin=y1, ymax=y2),
        alpha = 0, color = "black", lty = 2
      )
  })

  brush1key <- reactive({
    if (is.null(input$brush1)) return(NULL)
    brushedPoints(m, input$brush1)$key
  })

  output$res1 <- renderPrint({
    if (is.null(brush1key())) {
      return(tags$b("Brush the points outlined above"))
    }
    actual <- brush1key()
    expected <- filter(m, drv == "f", fl == "d") %>% pull(key)
    if (identical(sort(expected), sort(actual))) {
      tags$b("Test passed!", style = "color: green")
    } else {
      tags$b("Test failed", style = "color: red")
    }
  })

  brush2key <- reactive({
    if (is.null(input$brush2)) return(NULL)
    brushedPoints(m, input$brush2)$key
  })

  output$plot2 <- renderPlot({
    ggplot(m) +
      geom_point(aes(fl, cty)) +
      geom_rect(
        data = data.frame(
          x1 = 0.8,
          x2 = 1.2,
          y1 = 8,
          y2 = 12
        ),
        aes(xmin=x1, xmax=x2, ymin=y1, ymax=y2),
        alpha = 0, color = "black", lty = 2
      ) +
      scale_x_discrete(limits = c("e", "p"))
  })

  output$res2 <- renderPrint({
    if (is.null(brush2key())) {
      return(tags$b("Brush the points outlined above"))
    }
    actual <- brush2key()
    expected <- filter(m, fl == "e") %>% pull(key)
    if (identical(sort(expected), sort(actual))) {
      tags$b("Test passed!", style = "color: green")
    } else {
      tags$b("Test failed", style = "color: red")
    }
  })

  dat <- data.frame(
    x = c("a", "b", NA, NA),
    y = c(1, 2, 3, 2),
    key = c("a", "b", "c", "d"),
    stringsAsFactors = FALSE
  )

  output$plot3 <- renderPlot({
    ggplot(dat) +
      geom_point(aes(x, y)) +
      facet_wrap(~x, scales = "free") +
      geom_rect(
        data = data.frame(
          x1 = 0.8,
          x2 = 1.2,
          y1 = 2.9,
          y2 = 3.1,
          x = NA
        ),
        aes(xmin=x1, xmax=x2, ymin=y1, ymax=y2),
        alpha = 0, color = "black", lty = 2
      ) +
      ylim(1, 4)
  })

  brush3key <- reactive({
    if (is.null(input$brush3)) return(NULL)
    brushedPoints(dat, input$brush3)$key
  })

  output$res3 <- renderPrint({
    if (is.null(brush3key())) {
      return(tags$b("Brush the points outlined above"))
    }
    actual <- brush3key()
    if (identical(actual, "c")) {
      tags$b("Test passed!", style = "color: green")
    } else {
      tags$b("Test failed", style = "color: red")
    }
  })

}

shinyApp(ui, server)

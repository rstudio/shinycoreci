### Keep this line to manually test this shiny application. Do not edit this line; shinycoreci::::is_manual_app

library(shiny)
# Enable reactlog
library(reactlog)
reactlog_enable()

ui <- fluidPage(
  # Make sure body height does not change when taking screenshots
  tags$style("body { min-height: 100vh; }"),

  titlePanel("Hello Shiny!"),
  sidebarLayout(
    sidebarPanel(
      sliderInput(inputId = "bins",
                  label = "Number of bins:",
                  min = 1,
                  max = 50,
                  value = 30)

    ),
    mainPanel(
      plotOutput(outputId = "distPlot")
    )
  ),
  ### start ui module
  reactlog_module_ui()
  ### end ui module
)

server <- function(input, output, session) {
  x <- faithful$waiting
  bins <- reactive({
    seq(min(x), max(x), length.out = input$bins + 1)
  })
  output$distPlot <- renderPlot({

    hist(x, breaks = bins(), col = "#75AADB", border = "white",
         xlab = "Waiting time to next eruption (in mins)",
         main = "Histogram of waiting times")

  })

  ### start server module
  reactlog_module_server()
  ### end server module
}

shinyApp(ui = ui, server = server)

library(shiny)
library(reactlog)
reactlog_enable()

ui <- fluidPage(
  titlePanel("Dynamically generated user interface components"),
  fluidRow(

    column(3, wellPanel(
      selectInput("input_type", "Input type",
        c("slider", "text", "numeric", "checkbox",
          "checkboxGroup", "radioButtons", "selectInput",
          "selectInput (multi)", "date", "daterange"
        )
      )
    )),

    column(3, wellPanel(
      # This outputs the dynamic UI component
      uiOutput("ui")
    )),

    column(3,
      tags$p("Input type:"),
      verbatimTextOutput("input_type_text"),
      tags$p("Dynamic input value:"),
      verbatimTextOutput("dynamic_value")
    )
  ),
  ### start ui module
  reactlog_module_ui()
  ### end ui module
)

server <- function(input, output) {

  output$ui <- renderUI({
    if (is.null(input$input_type))
      return()

    # Depending on input$input_type, we'll generate a different
    # UI component and send it to the client.
    switch(input$input_type,
      "slider" = sliderInput("dynamic", "Dynamic",
                             min = 1, max = 20, value = 10),
      "text" = textInput("dynamic", "Dynamic",
                         value = "starting value"),
      "numeric" =  numericInput("dynamic", "Dynamic",
                                value = 12),
      "checkbox" = checkboxInput("dynamic", "Dynamic",
                                 value = TRUE),
      "checkboxGroup" = checkboxGroupInput("dynamic", "Dynamic",
        choices = c("Option 1" = "option1",
                    "Option 2" = "option2"),
        selected = "option2"
      ),
      "radioButtons" = radioButtons("dynamic", "Dynamic",
        choices = c("Option 1" = "option1",
                    "Option 2" = "option2"),
        selected = "option2"
      ),
      "selectInput" = selectInput("dynamic", "Dynamic",
        choices = c("Option 1" = "option1",
                    "Option 2" = "option2"),
        selected = "option2"
      ),
      "selectInput (multi)" = selectInput("dynamic", "Dynamic",
        choices = c("Option 1" = "option1",
                    "Option 2" = "option2"),
        selected = c("option1", "option2"),
        multiple = TRUE
      ),
      "date" = dateInput("dynamic", "Dynamic"),
      "daterange" = dateRangeInput("dynamic", "Dynamic")
    )
  })

  output$input_type_text <- renderText({
    input$input_type
  })

  output$dynamic_value <- renderPrint({
    str(input$dynamic)
  })

  ### start server module
  reactlog_module_server()
  ### end server module
}

shinyApp(ui = ui, server = server)

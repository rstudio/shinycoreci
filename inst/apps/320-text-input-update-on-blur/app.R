# https://github.com/rstudio/shiny/pull/4183
library(shiny)

random_values <- list(
  word = c(
    "serendipity",
    "ephemeral",
    "mellifluous",
    "nebulous",
    "quintessential",
    "ethereal",
    "luminescent",
    "cascade",
    "zenith",
    "labyrinth"
  ),

  sentence = c(
    "The old oak tree whispered secrets to the wind.",
    "Clouds painted shadows on the mountain peaks.",
    "Stars danced across the midnight canvas.",
    "Time flows like honey on a summer day.",
    "Music filled the empty spaces between thoughts."
  ),

  number = c(
    42,
    3.14159,
    1729,
    2.71828,
    1.41421,
    987654321,
    123.456,
    7.77777,
    9999.99,
    0.12345
  ),

  password = c(
    "Tr0ub4dor&3",
    "P@ssw0rd123!",
    "C0mpl3x1ty#",
    "S3cur3P@ss",
    "Str0ngP@55w0rd",
    "Un1qu3C0d3!",
    "K3yM@st3r99",
    "P@ssPhr@s3"
  )
)

random_value <- function(category, index) {
  selected_list <- random_values[[category]]
  wrapped_index <- (index - 1) %% length(selected_list) + 1

  return(selected_list[wrapped_index])
}


text_input_ui <- function(updateOn = "change") {
  ns <- NS(updateOn)

  tagList(
    h2(sprintf('updateOn="%s"', updateOn)),
    textInput(ns("txt"), "Text", "Hello", updateOn = updateOn),
    textAreaInput(ns("txtarea"), "Text Area", updateOn = updateOn),
    numericInput(ns("num"), "Numeric", 1, updateOn = updateOn),
    passwordInput(ns("pwd"), "Password", updateOn = updateOn),
    verbatimTextOutput(ns("value")),
    actionButton(ns("update_text"), "Update Text"),
    actionButton(ns("update_text_area"), "Update Text Area"),
    actionButton(ns("update_number"), "Update Number"),
    actionButton(ns("update_pwd"), "Update Password"),
  )
}

text_input_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    output$value <- renderText({
      paste(
        "---- Text ----",
        input$txt,
        "---- Text Area ----",
        input$txtarea,
        "---- Numeric ----",
        input$num,
        "---- Password ----",
        input$pwd,
        sep = "\n"
      )
    })

    observeEvent(input$update_text, {
      updateTextInput(
        session,
        "txt",
        value = paste(
          random_value("word", input$update_text + 0:1),
          collapse = " "
        )
      )
    })

    observeEvent(input$update_text_area, {
      updateTextAreaInput(
        session,
        "txtarea",
        value = paste(
          random_value("sentence", input$update_text_area + 0:1),
          collapse = "\n"
        )
      )
    })

    observeEvent(input$update_number, {
      updateNumericInput(
        session,
        "num",
        value = random_value("number", input$update_number)
      )
    })

    observeEvent(input$update_pwd, {
      updateTextInput(
        session,
        "pwd",
        value = random_value("password", input$update_pwd)
      )
    })
  })
}

ui <- fluidPage(
  fluidRow(
    column(6, class = "col-sm-12", text_input_ui("change")),
    column(6, class = "col-sm-12", text_input_ui("blur"))
  )
)

server <- function(input, output, session) {
  text_input_server("change")
  text_input_server("blur")
}

shinyApp(ui, server)

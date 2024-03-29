library(shiny)
library(bslib)

ui <- page_fixed(
  h1("Dynamic Sidebars"),
  tags$head(tags$title("bslib | Tests | Dynamic Sidebars")),
  div(id = "neutral-focus-zone", tabindex = "-1"),
  layout_columns(
    col_widths = c(6, 6, 6),
    card(
      id = "card-no-inputs",
      full_screen = TRUE,
      card_header("Nothing to focus on here"),
      p(
        "This is a boring card with just some plain text.",
        "There's something to read here but there aren't any inputs to focus on.",
        "Tabbing will only move focus to the \"Close\" button."
      )
    ),
    card(
      id = "card-with-inputs",
      full_screen = TRUE,
      card_header("Inputs, oh my!"),
      p(
        "Here's a bit of text! This card does have stuff to focus on, and the",
        "first focusable element is automatically focused when the card is expanded.",
        "Try tabbing through the inputs, you can't leave!"
      ),
      layout_column_wrap(
        width = "200px",
        card(
          id = "card-with-inputs-left",
          full_screen = TRUE,
          card_title("Left Column"),
          selectInput("letter", "Letter", letters, selected = "a"),
          selectizeInput("letter2", "Letter 2", letters, selected = "b", multiple = TRUE),
          dateRangeInput(
            inputId = "dates",
            label = "Pick a Date",
            start = "2023-05-01",
            end = "2023-05-31"
          )
        ),
        card(
          id = "card-with-inputs-right",
          full_screen = TRUE,
          card_title("Right Column"),
          sliderInput("slider", "Pick a Number", min = 1, max = 10, value = 5),
          textInput("word", "Word", "hello"),
          textAreaInput("sentence", "Sentence", "hello world")
        )
      ),
      actionButton("go", "Go")
    ),
    card(
      id = "card-with-plot",
      full_screen = TRUE,
      card_header("A plotly plot"),
      textInput("search", "Search", "search or something"),
      plotly::plot_ly(x = rnorm(1e4), y = rnorm(1e4))
    )
  )
)

server <- function(input, output, session) {
  # no server logic
}

shinyApp(ui, server)

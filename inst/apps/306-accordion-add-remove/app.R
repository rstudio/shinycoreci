library(shiny)
library(bslib)

make_item <- function(x) {
  accordion_item(
    paste("Section", x),
    paste("Some narrative for section", x),
    value = x
  )
}

ui <- page_fluid(
  # Don't transition when collapsing (so that we don't have
  # to wait to take screenshots)
  theme = bs_theme("transition-collapse" = "none"),
  layout_sidebar(
    list(
      selectInput(
        "selected", "Selected section(s)",
        LETTERS, multiple = TRUE, selected = "A"
      ),
      selectInput(
        "displayed", "Displayed section(s)",
        LETTERS, multiple = TRUE, selected = LETTERS
      ),
      checkboxInput("autoclose", "Auto closing accordion", FALSE),
      checkboxInput("insert_select", "Show on insert", FALSE)
    ),
    uiOutput("accordion")
  )
)

server <- function(input, output, session) {

  output$accordion <- renderUI({
    displayed(LETTERS)

    accordion(
      id = "acc", autoclose = input$autoclose,
      !!!lapply(LETTERS, make_item)
    )
  })

  observeEvent(input$selected, {
    accordion_select("acc", selected = input$selected)
  })

  displayed <- reactiveVal(LETTERS)

  observeEvent(input$displayed, {
    exit <- setdiff(displayed(), input$displayed)
    enter <- setdiff(input$displayed, displayed())

    if (length(exit)) {
      accordion_remove("acc", target = exit)
    }

    if (length(enter)) {
      lapply(enter, function(x) {
        # Find the next lowest currently displayed letter (to insert after)
        idx_displayed <- which(LETTERS %in% displayed())
        idx_insert <- match(x, LETTERS)
        idx_diff <- idx_insert - idx_displayed
        idx_diff[idx_diff < 0] <- NA
        target <- LETTERS[idx_displayed[which.min(idx_diff)]]
        accordion_insert("acc", item = make_item(x), target = target)
        displayed(c(x, displayed()))
      })

      if (input$insert_select) {
        accordion_select("acc", enter, close = input$autoclose)
      }
    }

    displayed(input$displayed)

    updateSelectInput(
      inputId = "selected", choices = input$displayed,
      selected = input$selected
    )
  })

}

shinyApp(ui, server)

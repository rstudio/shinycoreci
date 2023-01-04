library(shiny)
library(bslib)

make_panel <- function(x) {
  accordion_panel(
    paste("Section", x),
    paste("Some narrative for section", x),
    value = x
  )
}

ui <- fluidPage(
  # Don't transition when collapsing (so that we don't have
  # to wait to take screenshots)
  theme = bs_theme("transition-collapse" = "none"),
  sidebarLayout(
    sidebarPanel(
      selectInput(
        "selected", "Selected section(s)",
        LETTERS, multiple = TRUE, selected = "A"
      ),
      selectInput(
        "displayed", "Displayed section(s)",
        LETTERS, multiple = TRUE, selected = LETTERS
      ),
      checkboxInput("multiple", "Allow multiple panels to be open", TRUE),
      checkboxInput("open_on_insert", "Open on insert", FALSE)
    ),
    mainPanel(uiOutput("accordion"))
  )
)

server <- function(input, output, session) {

  # Allows us to track which panels are entering/exiting
  # (when input$displayed changes)
  displayed <- reactiveVal(LETTERS)

  output$accordion <- renderUI({
    displayed(LETTERS)

    accordion(
      id = "acc", multiple = input$multiple,
      !!!lapply(LETTERS, make_panel)
    )
  })

  observeEvent(input$selected, ignoreInit = TRUE, {
    accordion_panel_set("acc", input$selected)
  })

  observeEvent(input$acc, ignoreInit = TRUE, {
    updateSelectInput(inputId = "selected", selected = input$acc)
  })

  observeEvent(input$displayed, ignoreInit = TRUE, {
    exit <- setdiff(displayed(), input$displayed)
    enter <- setdiff(input$displayed, displayed())

    if (length(exit)) {
      accordion_panel_remove("acc", target = exit)
    }

    if (length(enter)) {
      lapply(enter, function(x) {
        # Find the next lowest currently displayed letter (to insert after)
        idx_displayed <- which(LETTERS %in% displayed())
        idx_insert <- match(x, LETTERS)
        idx_diff <- idx_insert - idx_displayed
        idx_diff[idx_diff < 0] <- NA
        target <- LETTERS[idx_displayed[which.min(idx_diff)]]
        accordion_panel_insert("acc", panel = make_panel(x), target = target)
        displayed(c(x, displayed()))
      })

      if (input$open_on_insert) {
        accordion_panel_open("acc", enter)
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

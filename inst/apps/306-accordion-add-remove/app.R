library(shiny)
library(bslib)

ui <- page_fill(
  theme = bs_theme(
    # Don't transition when collapsing (so screenshot timing is less of an issue)
    "transition-collapse" = "none",
    "accordion-bg" = "#1E1E1E",
    "accordion-color" = "white",
    "accordion-icon-color" = "white",
    "accordion-icon-active-color" = "white"
  ),
  layout_sidebar(
    border_radius = FALSE,
    border = FALSE,
    bg = "lightgray",
    sidebar(
      bg = "#1E1E1E",
      accordion(
        open = TRUE,
        accordion_panel(
          "Selected section(s)",
          selectInput("selected", NULL, LETTERS, multiple = TRUE, selected = "A"),
        ),
        accordion_panel(
          "Displayed section(s)",
          selectInput("displayed", NULL, LETTERS, multiple = TRUE, selected = LETTERS)
        ),
        accordion_panel(
          "Parameters",
          checkboxInput("multiple", "Allow multiple panels to be open", TRUE),
          checkboxInput("open_on_insert", "Open on insert", FALSE)
        )
      )
    ),
    uiOutput("accordion")
  )
)

server <- function(input, output, session) {

  make_panel <- function(x) {
    accordion_panel(
      paste("Section", x),
      paste("Some narrative for section", x),
      value = x
    )
  }

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
        panel <- make_panel(x)
        if (identical("A", x)) {

          # Can always be inserted at the top (no target required)
          accordion_panel_insert("acc", panel = panel, position = "before")

        } else {

          # Other letters require us to find the closest _currently displayed_
          # letter (to insert after)
          idx_displayed <- which(LETTERS %in% displayed())
          idx_insert <- match(x, LETTERS)
          idx_diff <- idx_insert - idx_displayed
          idx_diff[idx_diff < 0] <- NA
          target <- LETTERS[idx_displayed[which.min(idx_diff)]]
          accordion_panel_insert("acc", panel = panel, target = target, position = "after")

        }

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

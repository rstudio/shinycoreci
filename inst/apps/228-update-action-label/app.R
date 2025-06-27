library(shiny)
library(bslib)
library(shinyjster)

ui <- function(req) {
  page_fluid(
    shinyjster_js(readLines("test.js")),

    tags$h4("Test updating of action button/link label and icon"),

    uiOutput("ui"),

    tags$hr(),
    tags$p(class = "lead", "Update options"),
    tags$p(
      actionButton("new_label", "New label"),
      actionButton("new_icon", "New icon"),
      actionButton("new_label_icon", "New label & icon")
    ),
    tags$p(
      actionButton("clear_label", "Clear label"),
      actionButton("clear_icon", "Clear icon"),
      actionButton("clear_label_icon", "Clear label & icon")
    ),

    tags$hr(),
    tags$p(class = "lead", "Initial options"),
    tags$p(
      input_switch("as_link", "As link?", FALSE, width = "auto"),
      input_switch("initial_label", "Initial label?", TRUE, width = "auto"),
      input_switch("initial_icon", "Initial icon?", TRUE, width = "auto"),
    )
  )
}

server <- function(input, output, session) {
  shinyjster_server(input, output, session)

  output$ui <- renderUI({
    args <- list(
      inputId = "btn",
      label = if (input$initial_label) "Initial label" else NULL,
      icon = if (input$initial_icon) bsicons::bs_icon("heart") else NULL
    )

    if (input$as_link) {
      do.call(actionLink, args)
    } else {
      do.call(actionButton, args)
    }
  })

  i_label <- 1

  observeEvent(input$new_label, {
    new <- paste("New & fresh label", i_label)
    message(paste("Changing label to", new))
    updateActionButton(session, "btn", label = new)
    i_label <<- i_label + 1
  })

  icons <- c(
    "star",
    "info",
    "award",
    "trash",
    "search",
    "files",
    "virus",
    "check",
    "star"
  )

  observeEvent(input$new_icon, {
    new <- icons[1]
    message(paste("Changing icon to", new))
    updateActionButton(session, "btn", icon = bsicons::bs_icon(new))
    icons <<- c(icons[-1], new)  # Rotate the icon list
  })

  observeEvent(input$new_label_icon, {
    new_label <- paste("New & fresh label", i_label)
    new_icon <- icons[1]
    message(paste("Changing label to", new_label, "and icon to", new_icon))
    updateActionButton(session, "btn", label = new_label, icon = bsicons::bs_icon(new_icon))
    i_label <<- i_label + 1
    icons <<- c(icons[-1], new_icon)  # Rotate the icon list
  })

  observeEvent(input$clear_label, {
    updateActionButton(session, "btn", label = character(0))
  })

  observeEvent(input$clear_icon, {
    updateActionButton(session, "btn", icon = character(0))
  })

  observeEvent(input$clear_label_icon, {
    updateActionButton(session, "btn", label = character(0), icon = character(0))
  })

}

shinyApp(ui, server)

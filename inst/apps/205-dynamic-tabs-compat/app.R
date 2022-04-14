library(shiny)

card <- function(title, body) {
  div(
    class = "card",
    div(class = "card-header", title),
    div(class = "card-body", body)
  )
}

btn_ui <- function(id, show = TRUE, hide = TRUE) {
  ns <- NS(id)
  tagList(
    actionButton(ns('insert'), 'Insert'),
    actionButton(ns('remove'), 'Remove'),
    HTML("&nbsp;"),
    if (show) actionButton(ns('show'), 'Show'),
    if (hide) actionButton(ns('hide'), 'Hide')
  )
}

btn_server <- function(id, navId = id) {
  moduleServer(id, function(input, output, session) {

    ## keep track of elements inserted and not yet removed
    val <- 0L
    inserted <- c()

    observeEvent(input$insert, {
      value <- as.character(val)
      inserted <<- c(inserted, value)
      val <<- val + 1L
      insertTab(
        navId,
        navbarMenu(
          value,
          tabPanel("A", "A+ content"),
          "-----",
          tabPanel("B", "B- content")
        ),
        target = NULL
      )
    })

    observeEvent(input$remove, {
      if (!length(inserted)) return()
      removeTab(navId, tail(inserted, 1))
      inserted <<- head(inserted, -1)
    })

    observeEvent(input$show, showTab(navId, "base"))
    observeEvent(input$hide, hideTab(navId, "base"))
  })
}



ui <- navbarPage(
  title = "",
  theme = bslib::bs_global_get(),
  # Nav ids needs to be namespaced by the relevant btn_ui() id
  id = NS("navbar", "navbar"),
  tabPanel(
    "Home",
    card("navbarPage() controls", btn_ui("navbar", show = FALSE, hide = FALSE)),
    card(
      "tabsetPanel() controls",
      fluidRow(
        column(3, btn_ui("tabset")),
        column(
          9,
          tabsetPanel(
            id = NS("tabset", "tabset"),
            tabPanel("Base tab", value = "base", "This is a non-removable base tab")
          )
        )
      )
    ),
    card(
      "navlistPanel() controls",
      fluidRow(
        column(3, btn_ui("navlist")),
        column(
          9,
          navlistPanel(
            id = NS("navlist", "navlist"),
            tabPanel("Base tab", value = "base", "This is a non-removable base tab")
          )
        )
      )
    )
  )
)


server <- function(input, output, session) {
  btn_server("navbar")
  btn_server("tabset")
  btn_server("navlist")
}

shinyApp(ui, server)

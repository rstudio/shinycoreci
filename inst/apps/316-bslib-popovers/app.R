library(shiny)
library(bslib)
library(plotly)

ui <- page_navbar(
  title = "Popover tests",
  fillable = FALSE,
  id = "navbar",
  theme = bs_theme("enable-transitions" = interactive()),

  nav_panel(
    "Popover cases",
    inputPanel(
      class = "px-3 py-5",
      h3("Triggers"),
      popover(
        id = "pop-hello",
        "Hello popover",
        "Hello popover"
      ),
      popover(
        id = "pop-inline",
        span("Inline popover"),
        "Inline popover"
      ),
      popover(
        id = "pop-hyperlink",
        a("Hyperlink popover", href = "https://github.com"),
        "Hyperlink popover"
      ),
      popover(
        id = "pop-action-link",
        actionLink("btn_link", "actionLink()"),
        "actionLink() message"
      ),
      popover(
        id = "pop-action",
        actionButton("btn", "A button"),
        "Popover 1"
      ),
      popover(
        id = "pop-multiple",
        tagList(
          actionButton("btn2", "A button"),
          actionButton("btn3", "A button"),
        ),
        "A popover"
      )
    ),
    inputPanel(
      class = "px-3 py-5",
      h3("Options"),
      popover(
        span("Offset (50,50)", id = "pop-offset"),
        "This tip should appear 50px down/right",
        placement = "right",
        options = list(offset = c(50, 50))
      ),
      popover(
        span("No animation", id = "pop-animation"),
        "This tip shouldn't fade in/out",
        placement = "right",
        options = list(animation = FALSE)
      )
    )
  ),
  nav_panel(
    "Popover updates",
    layout_sidebar(
      card(
        card_header(
            popover(
              span(
                "Card title with popover",
                bsicons::bs_icon("question-circle-fill")
              ),
              "Popover message",
              id = "popover",
              placement = "right"
            )
        ),
        plotlyOutput("bars")
      ),
      sidebar = list(
        textInput("popover_msg", "Popover message", "Popover message"),
        textInput("popover_title", "Popover title", ""),
        actionButton("show_popover", "Show popover", class = "mb-3"),
        actionButton("hide_popover", "Hide popover")
      )
    )
  ),

  nav_panel(
    "Popover inputs",
    uiOutput("num_out"),
    popover(
      id = "btn_pop",
      actionButton("btn4", "Show popover"),
      "Change the number",
      numericInput("num", NULL, 1),
      selectInput("sel", "Select", state.name),
      title = "Input controls"
    ),
    actionLink("inc", "Increment number")
  )

)

server <- function(input, output, session) {

  observe({
    update_popover("popover", input$popover_msg)
  })

  observe({
    update_popover("popover", title = input$popover_title)
  })

  observeEvent(input$show_popover, {
    toggle_popover("popover", show = TRUE)
  })

  observeEvent(input$hide_popover, {
    toggle_popover("popover", show = FALSE)
  })

  output$bars <- renderPlotly({
    plot_ly(diamonds, x = ~cut)
  })

  output$num_out <- renderPrint({
    input$num
  })

  observeEvent(input$inc, {
    updateNumericInput(inputId = "num", value = input$num + 1)
  })
}

shinyApp(ui, server)

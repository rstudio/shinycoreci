#App to test insert tab and insert tab in dropdown Menu.
#Related to https://github.com/rstudio/shiny/pull/3315

library(shiny)
library(bslib)

ui <- fluidPage(
  theme = bs_theme(),
  sidebarLayout(
    sidebarPanel(
      actionButton("add", "Add 'Dynamic' tab"),
      actionButton("removeFoo", "Remove 'Foo' tabs"),
      actionButton("addFoo", "Add New 'Foo' tab")
    ),
    mainPanel(
      tabsetPanel(
        id = "tabs",
        tabPanel("Hello", "This is the hello tab"),
        tabPanel("Foo-0", "This is the Foo-0 tab", value = "Foo"),
        navbarMenu(menuName = "Menu",
          "Static",
          tabPanel("Static 1", "Static 1", value = "s1"),
          tabPanel("Static 2", "Static 2", value = "s2")
        )
      )
    )
  ),

  # Make sure body height does not change when taking screenshots
  tags$style("body { min-height: 100vh; }")
)

server <- function(input, output, session) {
  observeEvent(input$add, {
    id <- paste0("Dynamic-", input$add)
    insertTab(
      inputId = "tabs",
      tabPanel(id, id),
      target = "s2",
      position = "before"
    )
  })
  observeEvent(input$removeFoo, {
    removeTab(inputId = "tabs", target = "Foo")
  })
  observeEvent(input$addFoo, {
    insertTab(
      inputId = "tabs",
      tabPanel(
        paste0("Foo-", input$addFoo),
        paste0("This is the new Foo-", input$addFoo, " tab"),
        value = "Foo"
      ),
      target = "Menu",
      position = "before",
      select = TRUE)
  })

}

shinyApp(ui, server)

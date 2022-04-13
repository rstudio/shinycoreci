library(shiny)
# Enable reactlog
library(reactlog)
reactlog_enable()

ui <- fluidPage(
  tags$h1("Pythagorean theorem"),
  numericInput("a", "A", 3),
  numericInput("b", "B", 4),
  "C:", verbatimTextOutput("c"),
  ### start ui module
  reactlog_module_ui()
  ### end ui module
)

server <- function(input, output, session) {
  a2 <- reactive({a <- input$a; req(a); a * a}, label = "a^2")
  b2 <- reactive({b <- input$b; req(b); b * b}, label = "b^2")
  c2 <- reactive({a2() + b2()}, label = "c^2")
  c_val <- reactive({sqrt(c2())}, label = "c")

  output$c <- renderText({
    c_val()
  })

  ### start server module
  reactlog_module_server()
  ### end server module
}

shinyApp(ui = ui, server = server)

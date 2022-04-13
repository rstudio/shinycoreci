library(shiny)

# Main app UI
ui <- fluidPage(
  theme = bslib::bs_theme(version = 4, bootswatch = "darkly"),
  actionButton("openModalBtn", "Open Modal")
)

# Main app server
server <- function(input, output, session) {
  # open modal on button click
  observeEvent(input$openModalBtn,
               showModal(modalDialog(title="Hello",footer=actionButton("closeModalBtn", "Close Modal")))
  )

  # close modal on button click
  observeEvent(input$closeModalBtn, {
    removeModal()
  })
}

shinyApp(ui, server)

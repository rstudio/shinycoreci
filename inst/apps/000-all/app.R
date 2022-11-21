# library(shiny)

# ui <- fluidPage(
#   verbatimTextOutput("txt", placeholder = TRUE)
# )
# server <- function(input, output) {
#   output$txt <- renderText({
#     paste0(system("printenv", intern = TRUE), collapse = "\n")
#   })
# }

# shinyApp(ui, server)

# This app is very similar to 000-manual, any changes here should be made there
if (grepl("beta.rstudioconnect.com", Sys.getenv("CONNECT_SERVER", "not-found"), fixed = TRUE)) {
  message("On Connect!")
  shinycoreci:::test_in_connect(app_name = "001-hello", apps = shinycoreci:::apps_deploy, port = NULL)
} else if (grepl("shinyapps", Sys.getenv("R_CONFIG_ACTIVE", "not-found"))) {
  message("On shinyapps.io!")
  shinycoreci:::test_in_shinyappsio_app(app_name = "001-hello", apps = shinycoreci:::apps_deploy, port = NULL)
} else {
  stop(
    "Interactive environment.\n",
    "If in the IDE, please run `shinycoreci::test_in_ide()` to run each app individually.\n",
    "If wanting to test in the browser, please run `shinycoreci::test_in_browser()`."
  )
}

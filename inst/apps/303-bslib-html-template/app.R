library(shiny)
library(bslib)

ui <- htmlTemplate(
  "template.html",
  theme = bs_theme(
    version = 4, primary = "yellow",
    bg = "black", fg = "white",
    base_font = font_google("Yellowtail")
  ),
  date = dateInput("date", "Date", value = "2020-12-20"),
  date_range = dateRangeInput(
    "date_range", "Date",
    min = "2020-12-10",
    start = "2020-12-15",
    end = "2020-12-24",
    max = "2021-12-30"
  ),
  select = selectInput("select", "Single", choices = state.abb),
  select_multiple = selectInput("select_multiple", "Multiple", choices = c("Choose a state" = "", state.abb), multiple = TRUE),
  slider = sliderInput("slider", "Slider", min = 0, value = 70, max = 100),
  slider_multiple = sliderInput("slider_multiple", "Multiple", min = 0, value = c(50, 70), max = 100)
)

shinyApp(ui, function(input, output) {})

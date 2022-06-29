# This is a test of shinytest2's functionality for setting sliders with date
# values.
#
# Related issues:
# https://github.com/rstudio/shinytest2/issues/206
# https://github.com/rstudio/shinytest2/issues/228

library(shiny)

ui <- fluidPage(
  sliderInput(
    "decimal", "Decimal value",
    min = 0, max = 1, step = 0.1,
    value = 0.5
  ),
  sliderInput(
    "date", "Date",
    min = as.Date("2010-01-01"), max = as.Date("2010-06-01"),
    value = as.Date("2010-03-01")
  ),
  sliderInput(
    "date2", "Date2",
    min = as.Date("2010-01-01"), max = as.Date("2010-06-01"),
    value = c(as.Date("2010-02-01"), as.Date("2010-04-01"))
  ),
  sliderInput(
    "datetime", "Datetime",
    min = as.POSIXct("2010-01-01 10:00:00", format = "%Y-%m-%d %H:%M:%S", tz = "UTC"),
    max = as.POSIXct("2010-06-01 10:00:00", format = "%Y-%m-%d %H:%M:%S", tz = "UTC"),
    value = as.POSIXct("2010-03-01 10:00:00", format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
  ),
  sliderInput(
    "datetime2", "Datetime2",
    min = as.POSIXct("2010-01-01 10:00:00", format = "%Y-%m-%d %H:%M:%S", tz = "UTC"),
    max = as.POSIXct("2010-06-01 10:00:00", format = "%Y-%m-%d %H:%M:%S", tz = "UTC"),
    value = c(
      as.POSIXct("2010-02-01 10:00:00", format = "%Y-%m-%d %H:%M:%S", tz = "UTC"),
      as.POSIXct("2010-04-01 10:00:00", format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
    )
  )
)

server <- function(input, output, session) {}

shinyApp(ui, server)

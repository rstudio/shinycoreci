library(shinytest2)
library(testthat)

skip_on_platform("macos",
                 reason = "Only testing this on Windows and Linux"
)
test_that("Days of week and scatter points are present in chart", {
  app <- AppDriver$new(
    variant = shinytest2::platform_variant(),
    seed = 100
  )
  app$wait_for_value(input = "plot_type")
  app$set_inputs(plot_type = "scatter")
  app$wait_for_idle()

  # asserting all 7 days of the week show up within charts
  expected_days <- c("Monday", "Tuesday", "Wednesday", "Thursday",
                     "Friday", "Saturday", "Sunday")

  days_text <- app$get_text(".highcharts-xaxis-labels text")
  expect_true(all(expected_days %in% days_text))

  # Asserting only 7 scatter points in the charts
  points <- app$get_html(".highcharts-point")
  expect_length(points, 7)

  # asserting the chart has a width and height greater than 10
  width <- app$get_js("document.querySelector('.highcharts-background').getAttribute('width')")
  height <- app$get_js("document.querySelector('.highcharts-background').getAttribute('height')")
  expect_gt(as.numeric(width), 10)
  expect_gt(as.numeric(height), 10)

  app$stop()
})

library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(date = "2020-03-13")
  app$set_inputs(date2 = "2020-01-12")
  app$set_inputs(dateRange = c("2019-12-01", "2020-01-10"))
  app$set_inputs(dateRange = c("2019-12-01", "2020-04-24"))
  app$set_inputs(dateRange2 = c("2020-01-02", "2020-01-11"))
  app$set_inputs(dateRange2 = c("2020-01-02", "2020-01-17"))
  app$expect_values()
  app$expect_screenshot()
})

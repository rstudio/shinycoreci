library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(variable = "am")
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(variable = "gear")
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(outliers = FALSE)
  app$set_inputs(variable = "cyl")
  app$expect_values()
  app$expect_screenshot()
})

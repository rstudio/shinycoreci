library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(dataset = "pressure")
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(dataset = "cars")
  app$set_inputs(dataset = "pressure")
  app$set_inputs(dataset = "rock")
  app$expect_values()
  app$expect_screenshot()
})

library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(x1 = "CA")
  app$set_inputs(x4 = "NJ")
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(x2 = "OR")
  app$expect_values()
  app$expect_screenshot()
})

library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$set_inputs(n = 16)
  app$set_inputs(n = 11)
  app$set_inputs(n = 16)
  app$set_inputs(n = 9)
  app$set_inputs(n = 15)
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(n = 4)
  app$set_inputs(n = 20)
  app$expect_values()
  app$expect_screenshot()
})

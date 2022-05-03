library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$wait_for_idle()
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(freq = 35)
  app$set_inputs(max = 250)
  app$set_inputs(selection = "merchant")
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(selection = "romeo")
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(update = "click")
  app$set_inputs(freq = 10)
  app$expect_values()
  app$expect_screenshot()
})

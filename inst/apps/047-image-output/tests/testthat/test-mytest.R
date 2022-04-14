library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(r = 0.7)
  app$set_inputs(picture = "face")
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(r = 0.25)
  app$set_inputs(picture = "chainring")
  app$expect_values()
  app$expect_screenshot()
})

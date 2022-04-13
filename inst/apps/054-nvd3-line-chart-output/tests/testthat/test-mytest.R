library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  Sys.sleep(2)
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(sineAmplitude = -1.5)
  Sys.sleep(2)
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(sineAmplitude = -0.1)
  app$set_inputs(sinePhase = 100)
  Sys.sleep(2)
  app$expect_values()
  app$expect_screenshot()
})

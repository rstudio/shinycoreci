library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(`shinytheme-selector` = "lumen")
  Sys.sleep(2)
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(`shinytheme-selector` = "spacelab")
  Sys.sleep(2)
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(`shinytheme-selector` = "yeti")
  Sys.sleep(2)
  app$expect_values()
  app$expect_screenshot()
})

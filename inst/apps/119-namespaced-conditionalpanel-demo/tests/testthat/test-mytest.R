library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  Sys.sleep(1)
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(`plot1-n` = 180)
  Sys.sleep(0.5)
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(`plot2-n` = 190)
  Sys.sleep(0.5)
  app$expect_values()
  app$expect_screenshot()
})

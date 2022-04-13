library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new("../../index.Rmd", variant = shinytest2::platform_variant(),
    seed = 8296, shiny_args = list(display.mode = "normal"))
  Sys.sleep(4)
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(asp = 0.3)
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(asp = 0.02)
  app$set_inputs(asp = 0.3)
  app$set_inputs(asp = 0.02)
  app$set_inputs(size = 3.25)
  app$expect_values()
  app$expect_screenshot()
})

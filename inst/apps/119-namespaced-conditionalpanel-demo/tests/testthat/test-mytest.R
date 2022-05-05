library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$wait_for_idle()
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(`plot1-n` = 180)
  app$wait_for_idle()
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(`plot2-n` = 190)
  app$wait_for_idle()
  app$expect_values()
  app$expect_screenshot()
})

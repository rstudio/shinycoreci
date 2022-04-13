library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$wait_for_value(input = "inCheckboxGroup")
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(control_num = 8)
  app$expect_values()
  app$expect_screenshot()
})

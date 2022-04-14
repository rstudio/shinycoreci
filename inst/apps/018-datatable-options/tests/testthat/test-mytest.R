library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$wait_for_value(input = "ex1_rows_all")
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(tabs = "Length menu")

  app$wait_for_value(input = "ex2_rows_all")
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(tabs = "No pagination")

  app$wait_for_value(input = "ex3_rows_all")
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(tabs = "No filtering")

  app$wait_for_value(input = "ex4_rows_all")
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(tabs = "Function callback")

  app$wait_for_value(input = "ex5_rows_all")
  app$expect_values()
  app$expect_screenshot()
})

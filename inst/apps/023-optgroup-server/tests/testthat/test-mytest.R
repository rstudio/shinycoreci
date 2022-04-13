library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$wait_for_idle()
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(group = "17")

  app$wait_for_idle()
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(group = c("17", "30"))
  app$set_inputs(group = c("17", "30", "22"))
  app$set_inputs(group = c("17", "30", "22", "14"))
  app$set_inputs(group = c("17", "30", "22", "14", "20"))
  app$set_inputs(group = c("17", "30", "22", "14", "20", "8"))
  app$set_inputs(group = c("17", "30", "22", "14", "20", "8", "12"))

  app$wait_for_idle()
  app$expect_values()
  app$expect_screenshot()
})

library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  plotInit <- app$wait_for_value(output = "plot1", ignore = list(NULL,
    ""))
  app$expect_values()
  app$expect_screenshot()

  # Set inputs
  app$set_inputs(text = "hello world", wait_ = FALSE)
  app$set_inputs(n = 20, wait_ = FALSE)
  # Make sure the app does NOT change yet.
  app$expect_values()
  app$expect_screenshot()

  # Hit submit button
  app$get_js(script = "$('button[type=\"submit\"]').trigger('click')",
    timeout = 10000)
  app$wait_for_value(output = "plot1", ignore = list(NULL, plotInit))
  app$expect_values()
  app$expect_screenshot()
})

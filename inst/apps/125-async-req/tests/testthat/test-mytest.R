library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant())

  app$wait_for_value(output = "validateNeed_async")

  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(boom = "click")
  app$expect_values()
  app$expect_screenshot()
})

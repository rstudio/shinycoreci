library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant())

  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(sanitize = "TRUE")
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(tabset = "Using safeError()")
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(sanitize = "FALSE")
  app$expect_values()
  app$expect_screenshot()
})

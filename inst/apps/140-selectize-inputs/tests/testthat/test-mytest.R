library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant())

  # These are set by an update function - instead of setting them in our tests,
  # we'll wait for the app to automatically set them before moving on.
  # app$setInputs(`server-8-select` = "a1")
  # app$setInputs(`server-9-select` = "a1")
  # app$setInputs(`server-10-select` = "a1")
  # app$setInputs(`server-11-select` = "a1")

  app$wait_for_value(input = "server-8-select")
  app$wait_for_value(input = "server-9-select")
  app$wait_for_value(input = "server-10-select")
  app$wait_for_value(input = "server-11-select")
  app$wait_for_value(input = "server-12-select")
  app$wait_for_value(input = "server-13-select")
  app$expect_values()
  app$expect_screenshot()
})

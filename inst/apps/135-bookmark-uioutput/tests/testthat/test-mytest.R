library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant())

  app$wait_for_idle()
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(._bookmark_ = "click")
  app$wait_for_idle()
  app$expect_values()
  app$expect_screenshot(threshold = 2)

  app$set_inputs(x = 10)
  app$set_inputs(._bookmark_ = "click")
  app$wait_for_idle()
  app$expect_values()
  app$expect_screenshot(threshold = 2)

  app$set_inputs(reset = "click")
  app$expect_values()
  app$expect_screenshot(threshold = 2)
})

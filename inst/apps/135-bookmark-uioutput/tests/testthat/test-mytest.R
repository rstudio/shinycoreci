library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant())

  Sys.sleep(1)
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(._bookmark_ = "click")
  Sys.sleep(1)
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(x = 10)
  app$set_inputs(._bookmark_ = "click")
  Sys.sleep(1)
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(reset = "click")
  app$expect_values()
  app$expect_screenshot()
})

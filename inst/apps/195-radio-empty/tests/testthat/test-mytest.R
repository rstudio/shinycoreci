library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant())

  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(radio = "b")
  app$set_inputs(radio2 = "d")
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(empty = "click")
  app$set_inputs(rerender = "click")
  app$expect_values()
  app$expect_screenshot()
})

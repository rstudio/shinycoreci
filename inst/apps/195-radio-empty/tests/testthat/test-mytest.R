library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant())

  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(radio = "b")
  app$set_inputs(radio2 = "d")
  txt2_val <- app$wait_for_value(output = "txt2")
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(empty = "click")
  app$set_inputs(rerender = "click")
  app$wait_for_value(output = "txt2", ignore = list(txt2_val))
  app$expect_values()
  app$expect_screenshot()
})

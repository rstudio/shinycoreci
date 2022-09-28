skip_if_not_installed("reactR", "0.4")

library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant())

  app$set_inputs(simpleTextInput = "a")
  app$set_inputs(simpleTextInput = "ab")
  app$set_inputs(simpleTextInput = "abc")
  app$set_inputs(simpleTextInput = "abcd")
  app$set_inputs(simpleTextInput = "abcd1")
  app$set_inputs(simpleTextInput = "abcd12")
  app$set_inputs(simpleTextInput = "abcd123")
  app$set_inputs(simpleTextInput = "abcd1234")
  app$expect_values()
  app$expect_screenshot(threshold = 2)
  app$set_inputs(._bookmark_ = "click")
  Sys.sleep(1) # wait for modal
  app$expect_values()
  app$expect_screenshot(threshold = 2)
})

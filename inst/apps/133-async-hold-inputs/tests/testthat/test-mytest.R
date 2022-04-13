library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant())

  app$set_inputs(go = "click", wait_ = FALSE)
  app$set_inputs(choice = "b", wait_ = FALSE)
  app$set_inputs(choice = "c", wait_ = FALSE)
  app$expect_values()
  app$expect_screenshot()
  Sys.sleep(4)
  app$expect_values()
  app$expect_screenshot()
})

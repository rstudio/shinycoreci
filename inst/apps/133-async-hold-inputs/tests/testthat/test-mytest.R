library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant())

  app$set_inputs(go = "click", wait_ = FALSE)
  app$set_inputs(choice = "b", wait_ = FALSE)
  app$set_inputs(choice = "c", wait_ = FALSE)
  app$expect_values()

  ## Commenting because the screenshot may or may not get the right
  ## timing with the progress notification in the corner
  # app$expect_screenshot()

  app$wait_for_idle(duration = 1500)

  app$expect_values()
  app$expect_screenshot()
})

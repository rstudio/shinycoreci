library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(), wait = FALSE)

  app$set_inputs(go = "click", wait_ = FALSE)
  app$set_inputs(choice = "b", wait_ = FALSE)
  app$set_inputs(choice = "c", wait_ = FALSE)
  # Expect values before the first click calculation returns
  app$expect_values()

  ## Commenting because the screenshot may or may not get the right
  ## timing with the progress notification in the corner
  # app$expect_screenshot()

  # Must wait at least 3 seconds for each click to return
  # with a 2 second buffer on top of that
  app$wait_for_idle(timeout = (3 * 3 + 2) * 1000)

  app$expect_values()
  app$expect_screenshot()
})

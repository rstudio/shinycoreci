library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 54322)

  app$set_inputs(`reactlog_module-refresh` = "click")
  Sys.sleep(4)
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(a = 5, b = 12)

  app$set_inputs(`reactlog_module-refresh` = "click")
  Sys.sleep(4)
  app$expect_values()
  app$expect_screenshot()
})

library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100)

  # Progress won't work right with shinytest because of timing.
  #app$setInputs(progress = "click")
  #app$snapshot()
  app$set_inputs(dates = c("2000-01-19", "2018-02-01"))
  app$set_inputs(dates = c("2000-01-19", "2018-01-31"))
  # app$setInputs(progress = "click")
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(._bookmark_ = "click")
  Sys.sleep(1)
  app$expect_values()
  app$expect_screenshot()
})

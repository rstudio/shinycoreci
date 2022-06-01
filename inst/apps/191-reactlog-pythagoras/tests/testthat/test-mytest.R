library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100)

  refresh_and_expect <- function() {
    app$set_inputs(`reactlog_module-refresh` = "click")
    Sys.sleep(3) # wait for reactlog to settle
    app$expect_values()
    app$expect_screenshot()
  }

  refresh_and_expect()

  app$set_inputs(a = 5, b = 12)

  refresh_and_expect()
})

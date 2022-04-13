library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(format = "HTML", wait_ = FALSE)
  app$set_inputs(x = "disp")
  app$expect_values()
  app$expect_screenshot()
  app$expect_download("downloadReport")

  # Note: PDF and Word output are different each time, so we only test HTML
  # output.
})

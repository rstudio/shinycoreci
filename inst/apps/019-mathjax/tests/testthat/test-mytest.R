library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    load_timeout = 15000, seed = 100, shiny_args = list(display.mode = "normal"))

  Sys.sleep(3) # wait for mathjax to process
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(ex5_visible = TRUE)
  Sys.sleep(2) # wait for mathjax to process
  app$expect_values()
  app$expect_screenshot()
})

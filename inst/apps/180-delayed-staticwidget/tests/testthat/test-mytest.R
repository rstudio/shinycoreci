library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$wait_for_value(output = "status")

  Sys.sleep(2) # wait for map
  app$expect_values()
  app$expect_screenshot()
})

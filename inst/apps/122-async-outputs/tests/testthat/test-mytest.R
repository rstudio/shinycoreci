library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    load_timeout = 15000, seed = 100, shiny_args = list(display.mode = "normal"))

  # Wait until an async value is available
  app$wait_for_value(output = "printa")

  app$expect_values()
  app$expect_screenshot()
})

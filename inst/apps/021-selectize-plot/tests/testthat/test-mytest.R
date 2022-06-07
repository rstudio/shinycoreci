library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, height = 700, width = 1000  shiny_args = list(display.mode = "normal"))

  # Wait until the DT table is fully initialized
  init_parcoord <- app$wait_for_value(output = "parcoord", ignore = list(NULL,
    ""))
  app$wait_for_value(input = "rawdata_rows_current", ignore = list(NULL,
    ""))
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(state = "California")
  # Wait until the DT table is has new values
  app$wait_for_value(output = "parcoord", ignore = list(init_parcoord))

  app$expect_values()
  app$expect_screenshot()
})

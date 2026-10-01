library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(
    variant = shinytest2::platform_variant(),
    seed = 100,
    shiny_args = list(display.mode = "normal"),
    options = list("shiny.json.digits" = 4)
  )

  p_init <- app$get_value(output = "scatterPlot")
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(n = 10)
  p_hidden <- app$wait_for_value(
    output = "scatterPlot",
    ignore = list(NULL, p_init)
  )
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(n = 200)
  app$set_inputs(n = 80)
  app$set_inputs(n = 130)
  app$wait_for_value(
    output = "scatterPlot",
    ignore = list(NULL, p_init, p_hidden)
  )
  app$expect_values()
  app$expect_screenshot()
})

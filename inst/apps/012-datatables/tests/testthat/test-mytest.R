library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(
    variant = shinytest2::platform_variant(),
    seed = 100,
    shiny_args = list(display.mode = "normal"),
    height = 1300,
    width = 1200
  )

  app$wait_for_idle()
  # Input 'mytable1_rows_current' was set, but doesn't have an input binding.
  # Input 'mytable1_rows_all' was set, but doesn't have an input binding.
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(show_vars = c("carat", "cut", "color", "clarity",
    "depth", "price", "x", "y", "z"))
  # Input 'mytable1_rows_current' was set, but doesn't have an input binding.
  # Input 'mytable1_rows_all' was set, but doesn't have an input binding.
  app$set_inputs(show_vars = c("carat", "cut", "color", "clarity",
    "price", "x", "y", "z"))
  # Input 'mytable1_rows_current' was set, but doesn't have an input binding.
  # Input 'mytable1_rows_all' was set, but doesn't have an input binding.
  app$wait_for_idle()
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(show_vars = c("color", "clarity", "price", "y",
    "z"))
  # Input 'mytable1_rows_current' was set, but doesn't have an input binding.
  # Input 'mytable1_rows_all' was set, but doesn't have an input binding.
  app$set_inputs(show_vars = c("clarity", "price", "y", "z"))
  # Input 'mytable1_rows_current' was set, but doesn't have an input binding.
  # Input 'mytable1_rows_all' was set, but doesn't have an input binding.
  app$set_inputs(show_vars = c("price", "y", "z"))
  # Input 'mytable1_rows_current' was set, but doesn't have an input binding.
  # Input 'mytable1_rows_all' was set, but doesn't have an input binding.
  app$set_inputs(show_vars = c("y", "z"))
  # Input 'mytable1_rows_current' was set, but doesn't have an input binding.
  # Input 'mytable1_rows_all' was set, but doesn't have an input binding.
  app$set_inputs(show_vars = "z")
  app$wait_for_idle()
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(dataset = "mtcars")
  app$wait_for_idle()
  app$expect_values()
  app$expect_screenshot()
})

library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(xcol = "Petal.Length")
  app$set_inputs(ycol = "Petal.Width")
  app$set_inputs(clusters = 4)
  app$set_inputs(clusters = 5)
  app$set_inputs(clusters = 6)
  app$expect_values()
  app$expect_screenshot()
})

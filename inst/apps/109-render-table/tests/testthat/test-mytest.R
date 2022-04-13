library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(dataset = "mock")
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(format = "bordered")
  app$set_inputs(format = c("striped", "bordered"))
  app$set_inputs(spacing = "xs")
  app$set_inputs(align = "ccr")
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(align = "NULL")
  app$set_inputs(rownames = "T")
  app$set_inputs(digits = "3")
  app$set_inputs(na = "-99")
  app$expect_values()
  app$expect_screenshot()
})

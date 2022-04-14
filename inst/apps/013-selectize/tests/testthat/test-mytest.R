library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(e0 = "California")
  app$set_inputs(e3 = "Arizona")
  app$set_inputs(e5 = "Colorado")
  app$set_inputs(e5 = c("Colorado", "Connecticut"))
  app$set_inputs(e6 = "Arkansas")
  app$set_inputs(e7 = "Arizona")
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(e2 = "California")
  app$set_inputs(e4 = "Arizona")
  app$expect_values()
  app$expect_screenshot()
})

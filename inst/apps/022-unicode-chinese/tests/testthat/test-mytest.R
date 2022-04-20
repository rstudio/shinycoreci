library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(vars = "渗透性")
  app$expect_values()
  app$expect_screenshot()

  print(app$get_logs())

  app$set_inputs(obs = 4)
  app$set_inputs(obs = 7)
  app$set_inputs(obs = 8)
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(dataset = "cars")
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(summary = FALSE)
  app$expect_values()
  app$expect_screenshot()
})

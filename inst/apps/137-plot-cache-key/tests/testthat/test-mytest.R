library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(
    variant = shinytest2::platform_variant(),
    seed = 100,
    shiny_args = list(display.mode = "normal"),
    options = list("shiny.json.digits" = 4)
  )

  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(n = 250)
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(n = 100)
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(newdata = "click")
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(n = 300)
  app$expect_values()
  app$expect_screenshot()
})

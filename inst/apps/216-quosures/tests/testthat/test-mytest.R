library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(
    variant = shinytest2::platform_variant(),
    seed = 100,
    height = 1200, width = 1300,
    shiny_args = list(display.mode = "normal"),
    options = list("shiny.json.digits" = 4)
  )

  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(n = "click")

  app$expect_values()
  app$expect_screenshot()
})

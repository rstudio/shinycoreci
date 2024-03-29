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
  app$set_inputs(vars = "\u6e17\u900f\u6027")
  app$expect_values()
  app$expect_screenshot()
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

library(shinytest2)

# Temporary app-folder change for the CI precheck; safe to revert.
test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(
    variant = shinytest2::platform_variant(),
    seed = 100,
    shiny_args = list(display.mode = "normal"),
    options = list("shiny.json.digits" = 4)
  )

  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(variable = "am")
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(variable = "gear")
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(outliers = FALSE)
  app$set_inputs(variable = "cyl")
  app$expect_values()
  app$expect_screenshot()
})

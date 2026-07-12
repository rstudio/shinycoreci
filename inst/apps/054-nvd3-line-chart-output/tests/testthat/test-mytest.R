library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(
    variant = shinytest2::platform_variant(),
    seed = 100,
    shiny_args = list(display.mode = "normal"),
    options = list("shiny.json.digits" = 4)
  )

  app$expect_values()
  shinycoreci::expect_stable_screenshot(app)

  app$set_inputs(sineAmplitude = -1.5)
  app$expect_values()
  shinycoreci::expect_stable_screenshot(app)

  app$set_inputs(sineAmplitude = -0.1)
  app$set_inputs(sinePhase = 100)
  app$expect_values()
  shinycoreci::expect_stable_screenshot(app)
})

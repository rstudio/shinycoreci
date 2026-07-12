library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$expect_values()
  shinycoreci::expect_stable_screenshot(app)

  app$set_inputs(`shinytheme-selector` = "lumen")
  app$expect_values()
  shinycoreci::expect_stable_screenshot(app)

  app$set_inputs(`shinytheme-selector` = "spacelab")
  app$expect_values()
  shinycoreci::expect_stable_screenshot(app)

  app$set_inputs(`shinytheme-selector` = "yeti")
  app$expect_values()
  shinycoreci::expect_stable_screenshot(app)
})

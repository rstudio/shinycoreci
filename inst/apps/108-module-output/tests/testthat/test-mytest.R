library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(
    variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"),
    options = list("shiny.json.digits" = 4)
  )

  # Give extra wait time for brush input to be processed
  app$wait_for_idle()

  app$expect_values()
  app$expect_screenshot()
})

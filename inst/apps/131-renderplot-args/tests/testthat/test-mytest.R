library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(
    variant = shinytest2::platform_variant(),
    options = list("shiny.json.digits" = 4)
  )

  app$expect_values()
  app$expect_screenshot()
})

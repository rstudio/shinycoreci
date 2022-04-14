library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(
    variant = shinytest2::platform_variant(),
    options = list(shiny.autoload.r = TRUE)
  )

  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(`counter1-button` = "click")
  app$set_inputs(`counter1-button` = "click")
  app$expect_values()
  app$expect_screenshot()
})

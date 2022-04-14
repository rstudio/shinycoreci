skip_if_not_installed("htmltools", "0.5.0")

library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant())

  app$expect_values()
  app$expect_screenshot()
})

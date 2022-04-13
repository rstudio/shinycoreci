library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  skip_if_not_installed("ragg", "0.2")

  app <- AppDriver$new(variant = shinytest2::platform_variant())

  app$expect_values()
  app$expect_screenshot()
})

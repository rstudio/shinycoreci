library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    load_timeout = 15000)

  app$wait_for_value(output = "without_connection_upgrade")
  app$expect_values()
  app$expect_screenshot()
})

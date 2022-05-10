library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(), wait = FALSE)

  app$wait_for_value(export = "is_passing", ignore = list(NULL, FALSE), timeout = 30 * 1000)

  expect_equal(app$get_value(export = "is_passing"), TRUE)
})

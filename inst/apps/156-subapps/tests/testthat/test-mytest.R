library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new("../../index.Rmd", variant = shinytest2::platform_variant(),
    seed = 91546)

  app$expect_values()
  shinycoreci::expect_stable_screenshot(app)
})

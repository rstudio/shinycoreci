library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new("../../index.Rmd", variant = shinytest2::platform_variant(),
    seed = 91546)

  Sys.sleep(8) # wait for apps to load
  app$expect_values()
  app$expect_screenshot()
})

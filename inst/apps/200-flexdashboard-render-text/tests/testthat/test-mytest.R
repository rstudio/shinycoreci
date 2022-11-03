library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new("../../index.Rmd", variant = shinytest2::platform_variant(),
    seed = 75237)

  # wait some more time just to let the images adjust
  app$wait_for_idle()
  app$expect_values()
  app$expect_screenshot(threshold = 2)

  app$set_inputs(month = "Mar")
  # wait some more time just to let the images adjust
  app$wait_for_idle()
  app$expect_values()
  app$expect_screenshot(threshold = 2)

  # View second page
  app$run_js(script = "$(\"#navbar li a\").last().click();", timeout = 10000)
  app$wait_for_value(output = "p2r1content")
  # wait some more time just to let the images adjust
  app$wait_for_idle()
  app$expect_values()
  app$expect_screenshot(threshold = 2)
})

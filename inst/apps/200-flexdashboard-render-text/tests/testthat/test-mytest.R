library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new("../../index.Rmd", variant = shinytest2::platform_variant(),
    seed = 75237)

  app$wait_for_value(input = "plotly_afterplot-A")
  # wait some more time just to let the images adjust
  Sys.sleep(5)
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(month = "Mar")
  # wait some more time just to let the images adjust
  Sys.sleep(5)
  app$expect_values()
  app$expect_screenshot()

  # View second page
  app$run_js(script = "$(\"#navbar li a\").last().click();", timeout = 10000)
  app$wait_for_value(output = "p2r1content")
  # wait some more time just to let the images adjust
  Sys.sleep(5)
  app$expect_values()
  app$expect_screenshot()
})

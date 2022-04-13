library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant())


  app$wait_for_value(output = "plotNN")
  app$wait_for_value(output = "plotYN")
  app$wait_for_value(output = "plotNY")
  app$wait_for_value(output = "plotYY")

  app$wait_for_value(output = "ggplotNN")
  app$wait_for_value(output = "ggplotYN")
  app$wait_for_value(output = "ggplotNY")
  app$wait_for_value(output = "ggplotYY")

  app$expect_values()
  app$expect_screenshot()
})

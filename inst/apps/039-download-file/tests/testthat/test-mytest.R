library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$expect_values()
  app$expect_screenshot()
  app$expect_download("downloadData", compare = testthat::compare_file_text)
  app$set_inputs(filetype = "tsv")
  app$set_inputs(dataset = "Cars")
  app$set_inputs(dataset = "Pressure")
  app$expect_values()
  app$expect_screenshot()
  app$expect_download("downloadData", compare = testthat::compare_file_text)
})

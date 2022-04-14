library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$upload_file(file1 = "Rock.csv")
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(sep = ";")
  app$set_inputs(sep = ",")
  app$set_inputs(quote = "")
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(sep = ";")
  app$set_inputs(disp = "all")
  app$set_inputs(quote = "'")
  app$set_inputs(disp = "head")
  app$expect_values()
  app$expect_screenshot()
})

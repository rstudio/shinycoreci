library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(
    variant = shinytest2::platform_variant(),
    seed = 100,
    shiny_args = list(display.mode = "normal"),
    height = 1300,
    width = 1400
  )

  app$upload_file(file1 = "mtcars.csv")
  app$set_inputs(header = FALSE)
  app$set_inputs(quote = "")
  app$expect_values()
  app$expect_screenshot()
})

library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(
    variant = shinytest2::platform_variant(),
    # Use legacy datatable implementation just for the 
    # info$datatable$colnames test below. We could, of course, 
    # update that test, but it's also good to test the legacy.
    options = list(shiny.legacy.datatable = TRUE)
  )

  app$expect_values()
  app$expect_screenshot()
})

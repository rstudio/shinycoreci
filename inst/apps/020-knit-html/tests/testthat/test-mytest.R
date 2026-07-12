library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {

  skip_if(
    getRversion() < "3.6",
    "`rmarkdown::mark_html()` has difficulties being found in early R versions."
  )

  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$expect_values()
  shinycoreci::expect_stable_screenshot(app)

  app$set_inputs(x = "hp")
  app$expect_values()
  shinycoreci::expect_stable_screenshot(app)
})

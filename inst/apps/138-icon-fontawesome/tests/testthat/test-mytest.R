library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$expect_values()
  app$expect_screenshot()

  # Make sure no warnings about `Font Awesome` were thrown
  # See https://github.com/rstudio/fontawesome/pull/96
  # Ex warning:
  #> The `name` provided ('eur') is deprecated in Font Awesome 6:
  #> * please consider using 'euro-sign' or 'fas fa-euro-sign' instead
  #> * use the `verify_fa = FALSE` to deactivate these messages
  #> Running application in test mode.
  logs <- format(app$get_logs())
  expect_false(grepl("Font Awesome", logs))
})

test_that("Font Awesome Icons do not display warnings for historical icons", {
  # From within this app
  expect_warning(shiny::icon("eur"), NA)

  # https://github.com/rstudio/reactlog/pull/87
  expect_warning(shiny::icon("refresh"), NA)
})

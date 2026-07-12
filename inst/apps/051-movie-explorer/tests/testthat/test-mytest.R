library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {

  skip(paste(
    "Can not consistently pass on all builds...there some sort",
    "of timing issue where shinytest doesn't know how long to",
    "wait before taking a snapshot"
  ))

  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  Sys.sleep(3)
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(year = c(1988, 2014), wait_ = FALSE)
  app$set_inputs(year = c(2002, 2014), wait_ = FALSE)
  Sys.sleep(2)
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(year = c(2008, 2014), wait_ = FALSE)
  app$set_inputs(oscars = 1, wait_ = FALSE)
  Sys.sleep(2)
  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(oscars = 0, wait_ = FALSE)
  app$set_inputs(genre = "Animation", wait_ = FALSE)
  app$set_inputs(xvar = "Reviews", wait_ = FALSE)
  app$set_inputs(yvar = "BoxOffice", wait_ = FALSE)
  Sys.sleep(2)
  app$expect_values()
  app$expect_screenshot()
})

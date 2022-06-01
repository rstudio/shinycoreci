library(shinytest2)

# What is being tested is if shiny is capturing all of the dynamic inputs/outputs
# 191-reactlog-pythagoras tests on all platforms and r versions, so that functionality is covered

# Only run these tests on mac + r-release
# (To reduce the amount of screenshot diffing noise)
release <- rversions::r_release()$version
release <- paste0(
  strsplit(release, ".", fixed = TRUE)[[1]][1:2],
  collapse = "."
)
if (!identical(paste0("mac-", release), shinytest2::platform_variant())) {
  skip("Not mac + r-release")
}
if (length(dir("_snaps")) > 1) {
  stop("More than 1 _snaps folder found!")
}


test_that("Migrated shinytest test: mytest.R", {

  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  size <- list(height = 1200, width = 1100)
  refresh_and_expect <- function() {
    app$set_window_size(height = size$height, width = size$width)
    size$width <<- size$width + 25
    app$set_inputs(`reactlog_module-refresh` = "click")
    Sys.sleep(3) # wait for reactlog to settle
    app$expect_values()
    app$expect_screenshot()
  }

  refresh_and_expect()

  app$set_inputs(dynamic = 14)
  app$wait_for_idle()

  app$set_inputs(input_type = "text")
  app$wait_for_idle()
  app$set_inputs(dynamic = "abcd")
  app$wait_for_idle()

  app$set_inputs(input_type = "numeric")
  app$wait_for_idle()
  app$set_inputs(dynamic = 100)
  app$wait_for_idle()

  app$set_inputs(input_type = "checkbox")
  app$wait_for_idle()
  app$set_inputs(dynamic = FALSE)
  app$wait_for_idle()

  app$set_inputs(input_type = "checkboxGroup")
  app$wait_for_idle()
  app$set_inputs(dynamic = c("option1", "option2"))
  app$wait_for_idle()

  app$set_inputs(dynamic = "option1")
  app$wait_for_idle()
  app$set_inputs(dynamic = character(0))
  app$wait_for_idle()

  app$set_inputs(input_type = "radioButtons")
  app$wait_for_idle()
  app$set_inputs(dynamic = "option1")
  app$wait_for_idle()

  app$set_inputs(input_type = "selectInput")
  app$wait_for_idle()
  app$set_inputs(dynamic = "option1")
  app$wait_for_idle()

  app$set_inputs(input_type = "selectInput (multi)")
  app$wait_for_idle()

  app$set_inputs(dynamic = "option1")
  app$wait_for_idle()
  app$set_inputs(dynamic = character(0))
  app$wait_for_idle()

  app$set_inputs(input_type = "date")
  app$wait_for_idle()
  app$set_inputs(dynamic = "2020-01-31")
  app$wait_for_idle()

  app$set_inputs(input_type = "daterange")
  app$wait_for_idle()
  app$set_inputs(dynamic = c("2020-01-08", "2020-01-31"))
  app$wait_for_idle()

  refresh_and_expect()
})

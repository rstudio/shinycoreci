library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  size <- list(height = 1200, width = 1100)
  refresh_and_expect <- function() {
    # Adjust window size so that it is redrawn
    app$set_window_size(height = size$height, width = size$width)
    size$width <<- size$width + 25

    app$set_inputs(`reactlog_module-refresh` = "click")
    Sys.sleep(3) # wait for reactlog to settle
    app$expect_values()
    # app$expect_screenshot() # Not consistent. Disabling
  }

  refresh_and_expect()

  app$set_inputs(bins = 8)
  app$wait_for_idle()
  app$set_inputs(bins = 5)
  app$wait_for_idle()
  app$set_inputs(bins = 22)

  refresh_and_expect()
})

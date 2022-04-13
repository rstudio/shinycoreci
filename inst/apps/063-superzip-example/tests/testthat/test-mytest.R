library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  verbose <- FALSE
  if (verbose) {
    print(1)
    print(app$get_logs())
    cat("\n\n")
  }

  app$wait_for_value(output = "map")
  Sys.sleep(4) # let map fill in

  if (verbose) {
    print(2)
    print(app$get_logs())
    cat("\n\n")
  }

  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(threshold = 3)
  app$set_inputs(color = "college")

  Sys.sleep(4) # let map fill in

  if (verbose) {
    print(3)
    print(app$get_logs())
    cat("\n\n")
  }
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(nav = "Data explorer")

  ziptable_rows_all_init <- app$wait_for_value(input = "ziptable_rows_all")
  if (verbose) {
    print(4)
    print(app$get_logs())
    cat("\n\n")
  }
  app$expect_values()
  app$expect_screenshot()

  # Input 'ziptable_rows_current' was set, but doesn't have an input binding.
  # Input 'ziptable_rows_all' was set, but doesn't have an input binding.
  app$set_inputs(states = "MA")
  # Input 'ziptable_rows_current' was set, but doesn't have an input binding.
  # Input 'ziptable_rows_all' was set, but doesn't have an input binding.
  app$wait_for_value(input = "ziptable_rows_all", ignore = list(ziptable_rows_all_init))

  if (verbose) {
    print(5)
    print(app$get_logs())
    cat("\n\n")
  }
  app$expect_values()
  app$expect_screenshot()
})

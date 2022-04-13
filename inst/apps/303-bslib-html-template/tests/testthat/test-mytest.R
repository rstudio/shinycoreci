library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  library(shinytest)
  app <- AppDriver$new(variant = shinytest2::platform_variant())

  # date picker snapshots
  # TODO: do we need to wait until the calendar renders?
  app$run_js(script = "$('#date input').bsDatepicker('show')",
    timeout = 10000)
  app$expect_values()
  app$expect_screenshot()
  app$run_js(script = "$('#date input').bsDatepicker('hide')",
    timeout = 10000)

  app$run_js(script = "$('#date_range input:first').bsDatepicker('show')",
    timeout = 10000)
  app$expect_values()
  app$expect_screenshot()
  app$run_js(script = "$('#date_range input:first').bsDatepicker('hide')",
    timeout = 10000)

  wait_til_open <- function(css = ".selectize-dropdown-content *") {
    app$wait_for_js(paste0("$(\"", css, "\").length > 0"), timeout = 3000)
  }

  # Take snapshot of dropdown once it has content
  app$run_js(script = "$('#select')[0].selectize.open()", timeout = 10000)
  wait_til_open()
  Sys.sleep(1)
  app$expect_values()
  app$expect_screenshot()

  # Do the same for the selectInput(multiple=T)
  app$run_js(script = "$('#select')[0].selectize.close()", timeout = 10000)
  app$run_js(script = "$('#select_multiple')[0].selectize.open()",
    timeout = 10000)
  wait_til_open()
  Sys.sleep(1)
  app$expect_values()
  app$expect_screenshot()

  # Make sure the item styling is sensible
  app$run_js(script = "$('#select_multiple')[0].selectize.setValue(['MN', 'CA'])",
    timeout = 10000)
  app$expect_values()
  app$expect_screenshot()
  app$run_js(script = "$('#select_multiple')[0].selectize.close()",
    timeout = 10000)
})

library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$set_inputs(show = "click")
  Sys.sleep(1) # Wait for modal to appear
  app$expect_values()
  app$expect_screenshot(threshold = 2)

  # Click selectize input - https://github.com/rstudio/shiny/pull/3450
  app$get_js(script = "$('.selectize-input').click()", timeout = 10000)
  app$expect_values()
  app$expect_screenshot(threshold = 2)

  # Select an option
  app$set_inputs(selectizeInput = "California")
  app$expect_values()
  app$expect_screenshot(threshold = 2)

  # Verify the modal is closed when Dismiss is clicked
  app$get_js(script = "window.modalHidden = false;\n    $(document).on('hidden.bs.modal', function(e) {window.modalHidden = true; });",
    timeout = 10000)

  # Click the Dismiss button
  app$get_js(script = "$('button[data-dismiss=\"modal\"]').click()",
    timeout = 10000)
  app$wait_for_js("window.modalHidden", timeout = 3000)
  app$expect_values()
  app$expect_screenshot(threshold = 2)
})

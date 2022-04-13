library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  # Verify modal is open
  app$get_js(script = "window.modalShown = false;\n  $(document).on('shown.bs.modal', function(e) { window.modalShown = true; });",
    timeout = 10000)
  app$set_inputs(openModalBtn = "click")
  app$wait_for_js("window.modalShown", timeout = 3000)
  app$expect_values()
  app$expect_screenshot()


  # Verify modal is closed
  app$get_js(script = "window.modalHidden = false;\n  $(document).on('hidden.bs.modal', function(e) {window.modalHidden = true; });",
    timeout = 10000)
  app$set_inputs(closeModalBtn = "click")
  app$wait_for_js("window.modalHidden", timeout = 3000)
  app$expect_values()
  app$expect_screenshot()
})

library(shinytest2)

test_that("{shinytest2} recording: accordion-select", {
  width <- 995
  height <- 1336

  app <- AppDriver$new(
    variant = platform_variant(), name = "accordion-select",
    height = height, width = width,
    view = interactive(),
    options = list(bslib.precompiled = FALSE),
    screenshot_args = list(
      delay = 0.5,
      selector = "viewport",
      options = list(captureBeyondViewport = FALSE)
    )
  )

  # Make sure the set_input() calls complete in order
  set_inputs <- function(...) {
    app$set_inputs(...)
    app$wait_for_idle()
  }

  set_selected <- function(x, expected = x) {
    app$
      set_inputs(selected = x)$
      wait_for_idle()

    expect_selected(expected)
  }

  expect_selected <- function(x) {
    expect_equal(app$get_value(input = "selected"), !!x)
  }

  set_displayed <- function(x) {
    app$
      set_inputs(displayed = x)$
      wait_for_idle()

    displayed <- app$get_js(
      "[...document.querySelectorAll('#acc .accordion-item')].map(el => el.dataset.value)"
    )
    displayed <- unlist(displayed)
    expect_equal(displayed, x)
  }

  # Test accordion_panel_set()
  set_selected(c("A", "D"))
  set_selected(c("A", "D", "H"))
  app$expect_screenshot(threshold = 5)

  # Test accordion_panel_remove()
  set_displayed(c("D", "F"))
  expect_selected("D")

  # Test accordion_panel_insert()
  set_displayed(c("A", "D", "F"))
  expect_selected("D")
  set_displayed(c("A", "D", "F", "Z"))
  expect_selected("D")

  # Test accordion_panel_insert() + accordion_panel_open()
  set_inputs(open_on_insert = TRUE)
  set_displayed(c("A", "D", "F", "J", "Z"))
  expect_selected(c("D", "J"))

  set_displayed(c("A", "D", "F", "J", "K", "Z"))
  expect_selected(c("D", "J", "K"))
  app$expect_screenshot(threshold = 5)

  # redo tests with accordion(autoclose = TRUE)
  set_inputs(open_on_insert = FALSE)
  set_inputs(multiple = FALSE)

  # Last one (D) should be selected
  set_selected("B", expected = "B")
  set_selected(c("C", "D"), expected = "D")
  app$expect_screenshot(threshold = 5)

  set_displayed(c("A", "D", "F", "Z"))
  expect_selected("D")

  # Inserting a new open panel with multiple=FALSE selects just that panel
  set_inputs(open_on_insert = TRUE)
  set_displayed(c("A", "D", "F", "J", "Z"))
  expect_selected("J")

  set_displayed(c("A", "D", "F", "J", "K", "Z"))
  expect_selected("K")
  app$expect_screenshot(threshold = 5)
})

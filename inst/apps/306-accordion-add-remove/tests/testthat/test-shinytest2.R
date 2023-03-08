library(shinytest2)

test_that("{shinytest2} recording: accordion-select", {
  width <- 995
  height <- 1336

  app <- AppDriver$new(
    variant = platform_variant(), name = "accordion-select",
    height = height, width = width,
    view = interactive(),
    options = list(bslib.precompiled = FALSE)
  )

  # Make sure the set_input() calls complete in order
  set_inputs <- function(...) {
    app$set_inputs(...)
    app$wait_for_idle()
  }

  # Test accordion_panel_set()
  set_inputs(selected = c("A", "D"))
  set_inputs(selected = c("A", "D", "H"))
  app$expect_screenshot()

  # Test accordion_panel_remove()
  set_inputs(displayed = c("D", "F"))
  # Test accordion_panel_insert()
  set_inputs(displayed = c("A", "D", "F"))
  set_inputs(displayed = c("A", "D", "F", "Z"))
  # Test accordion_panel_insert() + accordion_panel_open()
  set_inputs(open_on_insert = TRUE)
  set_inputs(displayed = c("A", "D", "F", "J", "Z"))
  set_inputs(displayed = c("A", "D", "F", "J", "K", "Z"))
  app$expect_screenshot()

  # redo tests with accordion(autoclose = TRUE)
  set_inputs(open_on_insert = FALSE)
  set_inputs(multiple = FALSE)

  # Last one (D) should be selected
  set_inputs(selected = "B")
  set_inputs(selected = c("C", "D"))
  app$expect_screenshot()

  set_inputs(displayed = c("A", "D", "F", "Z"))
  set_inputs(open_on_insert = TRUE)
  set_inputs(displayed = c("A", "D", "F", "J", "Z"))
  set_inputs(displayed = c("A", "D", "F", "J", "K", "Z"))
  app$expect_screenshot()
})

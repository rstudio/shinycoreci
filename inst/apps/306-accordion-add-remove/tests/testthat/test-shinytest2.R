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

  expect_screenshot <- function(..., duration = 500, viewport = TRUE, threshold = 3) {
    app$wait_for_idle(duration = duration)
    args <- rlang::list2(..., threshold = threshold)
    if (viewport) {
      rect <- c(x = 0, y = 0, width = width, height = height)
      new_args <- list(screenshot_args = list(cliprect = rect))
      args <- modifyList(new_args, args)
    }
    do.call(app$expect_screenshot, args)
  }

  # Test accordion_panel_set()
  app$set_inputs(selected = c("A", "D"))
  app$set_inputs(selected = c("A", "D", "H"))
  expect_screenshot()

  # Test accordion_panel_remove()
  app$set_inputs(displayed = c("D", "F"))
  # Test accordion_panel_insert()
  app$set_inputs(displayed = c("A", "D", "F"))
  app$set_inputs(displayed = c("A", "D", "F", "Z"))
  # Test accordion_panel_insert() + accordion_panel_open()
  app$set_inputs(open_on_insert = TRUE)
  app$set_inputs(displayed = c("A", "D", "F", "J", "Z"))
  app$set_inputs(displayed = c("A", "D", "F", "J", "K", "Z"))
  expect_screenshot()

  # redo tests with accordion(autoclose = TRUE)
  app$set_inputs(open_on_insert = FALSE)
  app$set_inputs(multiple = FALSE)

  # Last one (D) should be selected
  app$set_inputs(selected = "B")
  app$set_inputs(selected = c("C", "D"))
  expect_screenshot()

  app$set_inputs(displayed = c("A", "D", "F", "Z"))
  app$set_inputs(open_on_insert = TRUE)
  app$set_inputs(displayed = c("A", "D", "F", "J", "Z"))
  app$set_inputs(displayed = c("A", "D", "F", "J", "K", "Z"))
  expect_screenshot()
})

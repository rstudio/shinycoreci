library(shinytest2)
if (FALSE) library(shinycoreci) # for renv

source(system.file("helpers", "keyboard.R", package = "shinycoreci"))

expect_focus <- function(app, selector) {
  js <- sprintf(
    "document.activeElement === document.querySelector('%s')",
    selector
  )
  expect_true(app$get_js(!!js))
  invisible(app)
}

# Setup App  ------------------------------------------------
app <- AppDriver$new(
  name = "314-bslib-tooltips",
  variant = platform_variant(),
  height = 800,
  width = 1200,
  seed = 20230714,
  view = interactive(),
  options = list(bslib.precompiled = FALSE),
  expect_values_screenshot_args = FALSE,
  screenshot_args = list(selector = "viewport", delay = 0.5)
)
withr::defer(app$stop())

key_press <- key_press_factory(app)

# Before focusing any tooltips, set up an event handler to keep track of
# the last tooltip shown
app$run_js(
  '$(document).on("shown.bs.tooltip", function(e) { window.lastShown = e.target; });'
)

# lastShown should contain the trigger element, which we can use to find the
# actual tooltip (we just make sure it's visible).
expect_visible_tip <- function(app, selector) {
  app$wait_for_js(
    sprintf("window.lastShown === document.querySelector('%s')", selector)
  )
  app$wait_for_js(
    "var tipId = window.lastShown.getAttribute('aria-describedby');
      $(`#${tipId}:visible`).length > 0;"
  )
}

# Tests for the 1st tab (Tooltip cases)
test_that("Can tab focus various cases/options", {
  expect_focus(app, "body")

  key_press("Tab")
  expect_focus(app, ".nav-link.active")

  # Placement ----------------------------------
  key_press("Tab")
  expect_focus(app, "#tip-auto")
  expect_visible_tip(app, "#tip-auto")

  key_press("Tab")
  expect_focus(app, "#tip-left")
  expect_visible_tip(app, "#tip-left")

  key_press("Tab")
  expect_focus(app, "#tip-right")
  expect_visible_tip(app, "#tip-right")

  key_press("Tab")
  expect_focus(app, "#tip-top")
  expect_visible_tip(app, "#tip-top")

  key_press("Tab")
  expect_focus(app, "#tip-bottom")
  expect_visible_tip(app, "#tip-bottom")

  # Triggers ----------------------------------
  key_press("Tab")
  expect_focus(app, "#tip-hello span")
  expect_visible_tip(app, "#tip-hello span")

  key_press("Tab")
  expect_focus(app, "#tip-inline span")
  expect_visible_tip(app, "#tip-inline span")

  key_press("Tab")
  expect_focus(app, "#tip-action button")
  expect_visible_tip(app, "#tip-action button")

  key_press("Tab")
  key_press("Tab")
  expect_focus(app, "#tip-multiple > :last-child")
  expect_visible_tip(app, "#tip-multiple > :last-child")

  # Options ----------------------------------
  key_press("Tab")
  expect_focus(app, "#tip-offset")
  expect_visible_tip(app, "#tip-offset")

  key_press("Tab")
  expect_focus(app, "#tip-animation")
  expect_visible_tip(app, "#tip-animation")
})



# Tests for the 2nd tab (Tooltip cases)
test_that("Can programmatically update/show/hide tooltip", {

  expect_no_tip <- function(app) {
    app$wait_for_js("$('.tooltip:visible').length === 0")
  }

  expect_tip_message <- function(app, msg) {
    app$wait_for_js(
      sprintf(
        "document.querySelector('.tooltip-inner').innerText === '%s'",
        msg
      )
    )
  }

  app$set_inputs("navbar" = "Tooltip updates")

  app$click("show_tooltip")
  expect_visible_tip(app, "#tooltip span")

  app$set_inputs("tooltip_msg" = "new")
  expect_tip_message(app, "new")

  app$click("hide_tooltip")
  expect_no_tip(app)

  app$set_inputs("tooltip_msg" = "newer")

  app$click("show_tooltip")
  expect_visible_tip(app, "#tooltip span")
  expect_tip_message(app, "newer")

  app$set_inputs("navbar" = "Tooltip cases")
  expect_no_tip(app)
})

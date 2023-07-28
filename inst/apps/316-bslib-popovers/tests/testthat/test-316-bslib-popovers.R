library(shinytest2)

# Only take screenshots on mac + r-release to reduce diff noise
release <- rversions::r_release()$version
release <- paste0(
  strsplit(release, ".", fixed = TRUE)[[1]][1:2],
  collapse = "."
)

is_testing_on_ci <- identical(Sys.getenv("CI"), "true") && testthat::is_testing()
is_mac_release <- identical(paste0("mac-", release), platform_variant())

DO_SCREENSHOT <- is_testing_on_ci && is_mac_release


source(system.file("helpers", "keyboard.R", package = "shinycoreci"))

expect_focus <- function(app, selector) {
  js <- sprintf(
    "document.activeElement === document.querySelector('%s')",
    selector
  )
  app$wait_for_js(js)
  invisible(app)
}

# Setup App  --------------------------------------------------
app <- AppDriver$new(
  name = "316-bslib-popovers",
  variant = platform_variant(),
  height = 800,
  width = 1200,
  seed = 20230724,
  view = interactive(),
  options = list(bslib.precompiled = FALSE),
  expect_values_screenshot_args = FALSE,
  screenshot_args = list(selector = "viewport", delay = 0.5)
)
withr::defer(app$stop())


# Setup App state and utility functions ------------------------

# Before focusing any tooltips, set up an event handler to keep
# track of the last tooltip shown
app$run_js(
  '$(document).on("shown.bs.popover", function(e) { window.lastShown = e.target; });'
)

key_press <- key_press_factory(app)

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

expect_no_tip <- function() {
  app$wait_for_js("$('.popover:visible').length === 0;")
}

click_close_button <- function() {
  app$click(selector = ".popover .btn-close")
}

expect_popover_content <- function(app, body = NULL, header = NULL) {
  body_js <- sprintf(
    "document.querySelector('.popover-body').innerText === '%s'",
    body
  )
  header_js <- sprintf(
    "document.querySelector('.popover-header').innerText === '%s'",
    header
  )
  if (!is.null(body)) app$wait_for_js(body_js)
  if (!is.null(header)) app$wait_for_js(header_js)
}


# Tests for the 1st tab (Popover cases)
test_that("Can tab focus various cases/options", {
  expect_focus(app, "body")

  key_press("Tab")
  expect_focus(app, ".nav-link.active")

  # Triggers ----------------------------------
  #  These aren't <a> tags, so Tab+Enter (or click)
  #  should show the popover
  key_press("Tab")
  key_press("Enter")
  expect_focus(app, "#pop-hello span")
  expect_visible_tip(app, "#pop-hello span")
  key_press("Enter")
  expect_no_tip()
  expect_focus(app, "#pop-hello span")

  # Make sure the popover is focusable via keyboard
  key_press("Enter")
  expect_focus(app, "#pop-hello span")
  expect_visible_tip(app, "#pop-hello span")
  key_press("Tab")
  expect_focus(app, ".popover")
  key_press("Tab")
  # At this point, focus should be on the close button, but we can't explictly
  # check for that since document.activeElement is empty for some reason, which
  # is really odd because if you $view() the app it's clearly focused and
  # document.activeElement isn't empty. We can implictly check for this though
  # by making sure we can Tab+Shift back to the trigger.
  key_press("Tab", shift = TRUE)
  key_press("Tab", shift = TRUE)
  expect_focus(app, "#pop-hello span")
  expect_visible_tip(app, "#pop-hello span")

  click_close_button()
  expect_focus(app, "#pop-hello span")
  expect_no_tip()

  key_press("Enter")
  expect_focus(app, "#pop-hello span")
  expect_visible_tip(app, "#pop-hello span")
  key_press("Escape")
  expect_focus(app, "#pop-hello span")
  expect_no_tip()
  key_press("Enter")
  expect_focus(app, "#pop-hello span")
  expect_visible_tip(app, "#pop-hello span")
  key_press("Tab")
  key_press("Tab")
  key_press("Escape")
  expect_focus(app, "#pop-hello span")
  expect_no_tip()

  key_press("Tab")
  key_press("Enter")
  expect_focus(app, "#pop-inline span")
  expect_visible_tip(app, "#pop-inline span")
  key_press("Enter")
  expect_no_tip()

  key_press("Tab")
  expect_focus(app, "#pop-hyperlink a")
  expect_visible_tip(app, "#pop-hyperlink a")

  key_press("Tab")
  expect_no_tip()
  key_press("Enter")
  expect_focus(app, "#btn_link")
  expect_visible_tip(app, "#btn_link")
  key_press("Enter")
  expect_no_tip()
  expect_true(app$get_value(input = "btn_link") == 2)

  # For some odd reason it seems a key_press("Enter") on a <button> doesn't
  # simulate a click event? This seems to be a chromote specific issue.
  expect_no_tip()
  app$click(selector = "#btn")
  expect_visible_tip(app, "#btn")
  click_close_button()
  expect_no_tip()
  expect_focus(app, "#btn")

  app$click(selector = "#btn3")
  expect_visible_tip(app, "#btn3")
  click_close_button()
  expect_no_tip()
  expect_focus(app, "#btn3")

  app$click(selector = "#pop-offset")
  expect_visible_tip(app, "#pop-offset")
})



# Tests for the 2nd tab (Tooltip cases)
test_that("Can programmatically update/show/hide tooltip", {

  app$set_inputs("navbar" = "Popover updates")

  app$click("show_popover")
  expect_popover_content(app, "Popover message")

  app$set_inputs("popover_msg" = "new")
  expect_popover_content(app, "new")

  app$click("hide_popover")
  expect_no_tip()

  app$set_inputs("popover_msg" = "newer")

  app$click("show_popover")
  expect_popover_content(app, "newer")

  app$set_inputs("navbar" = "Popover cases")
  expect_no_tip()
  app$set_inputs("navbar" = "Popover updates")

  app$set_inputs("show_title" = TRUE)
  app$click("show_popover")
  expect_popover_content(app, "newer", "Popover title")

  app$set_inputs("show_title" = FALSE)
  expect_popover_content(app, "newer", "")

})


# Tests for the 3rd tab (Tooltip inputs)
test_that("Can put input controls in the popover", {

  app$set_inputs("navbar" = "Popover inputs")

  key_press("Tab")
  key_press("Tab")
  app$click(selector = "#btn4")
  expect_visible_tip(app, "#btn4")
  key_press("Tab")
  expect_focus(app, ".popover")
  key_press("Tab")
  key_press("ArrowUp")
  key_press("ArrowUp")
  expect_equal(app$get_value(input = "num"), 3)
  app$click("inc")
  app$click("inc")
  expect_equal(app$get_value(input = "num"), 5)
  key_press("ArrowDown")
  expect_equal(app$get_value(input = "num"), 4)
  key_press("Escape")
  expect_focus(app, "#btn4")
  expect_no_tip()
  app$click("inc")
  app$click("inc")
  expect_equal(app$get_value(input = "num"), 6)
  app$click(selector = "#btn4")
  expect_visible_tip(app, "#btn4")
  # Even though the tip is visible, it seems it's not always ready to be
  # tabbed into, so wait a bit before doing so
  {Sys.sleep(0.5); key_press("Tab")}
  expect_focus(app, '.popover')
  key_press("Tab")
  expect_focus(app, 'input#num')
  key_press("Tab")
  expect_focus(app, 'input#sel-selectized')

  if (DO_SCREENSHOT) app$expect_screenshot()

  key_press("Escape")
  expect_visible_tip(app, "#btn4")
  click_close_button()
  expect_no_tip()
})

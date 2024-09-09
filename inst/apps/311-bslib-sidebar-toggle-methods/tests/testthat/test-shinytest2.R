library(shinytest2)
if (FALSE) library(shinycoreci) # for renv

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

expect_sidebar_hidden_factory <- function(app) {
  function(which = c("inner", "outer")) {
    state <- app$get_js(js_sidebar_state(which = which))
    expect_true("sidebar-collapsed" %in% state$layout_classes)
    expect_equal(state$content_display, "none")
    expect_true(state$sidebar_hidden)
  }
}

expect_sidebar_shown_factory <- function(app) {
  function(which = c("inner", "outer")) {
    state <- app$get_js(js_sidebar_state(which = which))
    expect_false("sidebar-collapsed" %in% state$layout_classes)
    expect_false(identical(state$content_display, "none"))
    expect_false(state$sidebar_hidden)
  }
}

js_sidebar_transition_complete <- function(which = c("inner", "outer")) {
  which <- match.arg(which)
  selector <- sprintf("#sidebar_%s", which)
  sprintf(
    "!document.querySelector('%s').parentElement.classList.contains('transitioning');",
    selector
  )
}

js_sidebar_state <- function(which = c("inner", "outer")) {
  which <- match.arg(which)
  selector <- sprintf("#sidebar_%s", which)
  sprintf(
    "(function() {
      return {
      layout_classes: Array.from(document.querySelector('%s').closest('.bslib-sidebar-layout').classList),
      content_display: window.getComputedStyle(document.querySelector('%s .sidebar-content')).getPropertyValue('display'),
      sidebar_hidden: document.querySelector('%s').hidden
    }})();",
    selector, selector, selector
  )
}

# 311-bslib-sidebar-toggle-methods: test all sidebar toggling methods -------
test_that("311-bslib-sidebar-toggle-methods", {
  app <- AppDriver$new(
    name = "311-bslib-sidebar-toggle-methods",
    variant = platform_variant(),
    height = 800,
    width = 1200,
    view = interactive(),
    options = list(bslib.precompiled = FALSE),
    expect_values_screenshot_args = FALSE
  )

  expect_sidebar_hidden <- expect_sidebar_hidden_factory(app)
  expect_sidebar_shown <- expect_sidebar_shown_factory(app)
  # use chrome dev tools to send a tab keypress to the body
  key_press <- key_press_factory(app)

  # First tab press enters the main content before sidebars
  key_press("Tab")
  expect_equal(
    app$get_js("document.activeElement.dataset.testId"),
    "main-content-area"
  )

  # Next tab enters the input in the inner sidebar
  key_press("Tab")
  expect_equal(
    app$get_js("document.activeElement.id"),
    "animal-selectized"
  )

  # Next tab focuses the inner sidebar collapse toggle
  key_press("Tab")
  expect_equal(
    app$get_js("document.activeElement.getAttribute('aria-controls')"),
    "sidebar_inner"
  )

  # Clicking this toggle hides the inner sidebar (note we can't directly test
  # the enter/space event handlers because headless chrome uses mobile emulation).
  app$
    click(selector = ":focus")$
    wait_for_js(js_sidebar_transition_complete("inner"))$
    expect_values()

  expect_sidebar_hidden("inner")
  expect_sidebar_shown("outer")

  # Next tab focuses the input in the outer sidebar
  key_press("Tab")
  expect_equal(
    app$get_js("document.activeElement.id"),
    "adjective-selectized"
  )

  # Next tab focuses the outer sidebar collapse toggle
  key_press("Tab")
  expect_equal(
    app$get_js("document.activeElement.getAttribute('aria-controls')"),
    "sidebar_outer"
  )

  # Clicking this toggle hides the outer sidebar
  app$
    click(selector = ":focus")$
    wait_for_js(js_sidebar_transition_complete("outer"))$
    expect_values()

  expect_sidebar_hidden("inner")
  expect_sidebar_hidden("outer")

  # Next tab focuses on next input in the document
  key_press("Tab")
  expect_equal(
    app$get_js("document.activeElement.id"),
    "show_all"
  )

  # Tabbing back into sidebar moves focus to outer toggle button
  key_press("Tab", shift = TRUE)
  expect_equal(
    app$get_js("document.activeElement.getAttribute('aria-controls')"),
    "sidebar_outer"
  )

  # Then to the inner toggle button
  key_press("Tab", shift = TRUE)
  expect_equal(
    app$get_js("document.activeElement.getAttribute('aria-controls')"),
    "sidebar_inner"
  )

  # Then into the sidebar main area
  key_press("Tab", shift = TRUE)
  expect_equal(
    app$get_js("document.activeElement.dataset.testId"),
    "main-content-area"
  )

  # Trigger server-side expansion of all sidebars
  app$
    click("show_all")$
    wait_for_js(js_sidebar_transition_complete("inner"))$
    wait_for_js(js_sidebar_transition_complete("outer"))$
    expect_values()

  expect_sidebar_shown("inner")
  expect_sidebar_shown("outer")

  # Trigger server-side collapse of inner sidebar
  app$
    click("toggle_inner")$
    wait_for_js(js_sidebar_transition_complete("inner"))$
    expect_values()

  expect_sidebar_hidden("inner")
  expect_sidebar_shown("outer")

  # Trigger server-side collapse of outer sidebar
  app$
    click("toggle_outer")$
    wait_for_js(js_sidebar_transition_complete("outer"))$
    expect_values()

  expect_sidebar_hidden("inner")
  expect_sidebar_hidden("outer")
})

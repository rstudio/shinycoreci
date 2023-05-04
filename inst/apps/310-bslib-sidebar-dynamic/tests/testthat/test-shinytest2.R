library(shinytest2)

# Only run these tests on mac + r-release
# (To reduce the amount of screenshot diffing noise)
release <- rversions::r_release()$version
release <- paste0(
  strsplit(release, ".", fixed = TRUE)[[1]][1:2],
  collapse = "."
)

is_testing_on_ci <- identical(Sys.getenv("CI"), "true") && testthat::is_testing()
is_mac_release <- identical(paste0("mac-", release), platform_variant())

if (is_testing_on_ci && !is_mac_release) {
  skip("Not mac + r-release")
}

key_press_factory <- function(app) {
  brwsr <- app$get_chromote_session()

  function(which = "Tab", shift = FALSE) {
    virtual_code <- switch(
      which,
      Tab = 9,
      Enter = 13,
      Escape = 27,
      ArrowLeft = 37,
      ArrowUp = 38,
      ArrowRight = 39,
      ArrowDown = 40,
      Backspace = 8,
      Delete = 46,
      Home = 36,
      End = 35,
      PageUp = 33,
      PageDown = 34,
      Space = 32
    )

    modifiers <- 0
    if (shift) modifiers <- modifiers + 8
    # if (command) modifiers <- modifiers + 4
    # if (control) modifiers <- modifiers + 2
    # if (alt) modifiers <- modifiers + 1

    events <-
      brwsr$Input$dispatchKeyEvent(
        "rawKeyDown",
        windowsVirtualKeyCode = virtual_code,
        code = which,
        key = which,
        modifiers = modifiers,
        wait_ = FALSE
      )$then(
        brwsr$Input$dispatchKeyEvent(
          "keyUp",
          windowsVirtualKeyCode = virtual_code,
          code = which,
          key = which,
          modifiers = modifiers,
          wait_ = FALSE
        )
      )

    brwsr$wait_for(events)

    invisible(app)
  }
}

expect_sidebar_hidden_factory <- function(app) {
  function(id, which = c("inner", "outer")) {
    state <- app$get_js(js_sidebar_state(id = id, which = which))
    expect_true("sidebar-collapsed" %in% state$layout_classes)
    expect_equal(state$content_display, "none")
    expect_true(state$sidebar_hidden)
  }
}

expect_sidebar_shown_factory <- function(app) {
  function(id, which = c("inner", "outer")) {
    state <- app$get_js(js_sidebar_state(id = id, which = which))
    expect_false("sidebar-collapsed" %in% state$layout_classes)
    expect_false(identical(state$content_display, "none"))
    expect_false(state$sidebar_hidden)
  }
}

js_sidebar_transition_complete <- function(id, which = c("inner", "outer")) {
  which <- match.arg(which)
  selector <- sprintf("#sidebar_%s_%s", which, id)
  sprintf(
    "!document.querySelector('%s').parentElement.classList.contains('transitioning');",
    selector
  )
}

js_sidebar_state <- function(id, which = c("inner", "outer")) {
  which <- match.arg(which)
  selector <- sprintf("#sidebar_%s_%s", which, id)
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

# 310-bslib-sidebar-dynamic: dynamically added sidebars -----------------------
test_that("310-bslib-sidebar-dynamic: dynamically added sidebars are fully functional", {
  app <- AppDriver$new(
    name = "310-bslib-sidebar-dynamic",
    variant = platform_variant(),
    height = 800,
    width = 1200,
    view = interactive(),
    options = list(bslib.precompiled = FALSE),
    expect_values_screenshot_args = FALSE
  )

  expect_sidebar_hidden <- expect_sidebar_hidden_factory(app)
  expect_sidebar_shown <- expect_sidebar_shown_factory(app)

  expect_sidebar_main_text <- function(id, pattern, ...) {
    text <- app$get_js(sprintf("document.querySelector('#main_inner_%s').textContent", id))
    expect_match(text, pattern, ...)
  }

  # Add first sidebar -----
  app$
    click("add_sidebar")$
    wait_for_js("document.getElementById('layout_1') ? true : false")$
    expect_values()

  app$expect_screenshot(selector = "#layout_1")
  expect_sidebar_main_text(1, "cuddly giraffe")

  # First sidebar starts open = "open"
  expect_sidebar_shown(id = 1, "inner")
  expect_sidebar_shown(id = 1, "outer")

  # Update an input in the sidebar to test that the output is updated
  app$set_inputs(adjective_1 = "elegant")
  expect_sidebar_main_text(1, "elegant giraffe")

  # Collapse the inner sidebar
  app$
    click(selector = "#main_inner_1 ~ .collapse-toggle")$
    wait_for_js(js_sidebar_transition_complete(id = 1))$
    expect_values()

  # Only inner sidebar is hidden
  expect_sidebar_hidden(id = 1, "inner")
  expect_sidebar_shown(id = 1, "outer")
  app$expect_screenshot(selector = "#layout_1")

  # Collapse the outer sidebar
  app$
    click(selector = "#main_outer_1 ~ .collapse-toggle")$
    wait_for_js(js_sidebar_transition_complete(id = 1, "outer"))$
    expect_values()

  # both sidebars are collapsed
  expect_sidebar_hidden(id = 1, "inner")
  expect_sidebar_hidden(id = 1, "outer")
  app$expect_screenshot(selector = "#layout_1")

  # Expand inner sidebar
  app$
    click(selector = "#main_inner_1 ~ .collapse-toggle")$
    wait_for_js(js_sidebar_transition_complete(id = 1))$
    expect_values()

  # Only inner sidebar is hidden
  expect_sidebar_shown(id = 1, "inner")
  expect_sidebar_hidden(id = 1, "outer")
  app$expect_screenshot(selector = "#layout_1")

  # Expand the outer sidebar
  app$
    click(selector = "#main_outer_1 ~ .collapse-toggle")$
    wait_for_js(js_sidebar_transition_complete(id = 1, "outer"))$
    expect_values()

  # both sidebars are shown
  expect_sidebar_shown(id = 1, "inner")
  expect_sidebar_shown(id = 1, "outer")
  app$expect_screenshot(selector = "#layout_1")

  # Update both inputs
  app$set_inputs(animal_1 = "panda", adjective_1 = "silly")
  expect_sidebar_main_text(1, "silly panda")

  # Add second sidebar -----
  app$
    click("add_sidebar")$
    wait_for_js("document.getElementById('layout_2') ? true : false")$
    expect_values()
  expect_sidebar_main_text(2, "elegant jaguar")

  # both sidebars are hidden because open = "closed"
  expect_sidebar_hidden(id = 2, "inner")
  expect_sidebar_hidden(id = 2, "outer")
  app$expect_screenshot(selector = "#layout_2")

  # Change an input while it's hidden
  app$set_inputs(animal_2 = "zebra")
  expect_sidebar_main_text(2, "elegant zebra")

  # Expand the outer sidebar
  app$
    click(selector = "#main_outer_2 ~ .collapse-toggle")$
    wait_for_js(js_sidebar_transition_complete(id = 2, "outer"))$
    expect_values()

  # Outer sidebar is revealed
  expect_sidebar_hidden(id = 2, "inner")
  expect_sidebar_shown(id = 2, "outer")
  app$expect_screenshot(selector = "#layout_2")

  # Switch to mobile app size, using iPhone 13 dimensions
  app$set_window_size(390, 844)

  # Write a javascript string to scroll #layout_2 into view
  app$
    run_js("document.getElementById('layout_2').scrollIntoView()")$
    expect_screenshot(selector = "#layout_2")

  # Add third sidebar -----
  app$
    click("add_sidebar")$
    wait_for_js("document.getElementById('layout_3') ? true : false")$
    run_js("document.getElementById('layout_3').scrollIntoView()")$
    # sidebar is closed immediately upon adding when open = "desktop"
    wait_for_js(js_sidebar_transition_complete(id = 3))$
    expect_values()

  expect_sidebar_main_text(3, "fierce koala")

  # both sidebars are hidden because open = "closed"
  expect_sidebar_hidden(id = 3, "inner")
  expect_sidebar_hidden(id = 3, "outer")
  app$expect_screenshot(selector = "#layout_3")

  # reveal inner sidebar
  app$
    click(selector = "#main_inner_3 ~ .collapse-toggle")$
    wait_for_js(js_sidebar_transition_complete(id = 3, "inner"))$
    run_js("document.getElementById('add_sidebar').scrollIntoView()")$
    expect_values()

  # inner sidebar is revealed
  expect_sidebar_shown(id = 3, "inner")
  expect_sidebar_hidden(id = 3, "outer")

  # change the input value
  app$set_inputs(animal_3 = "lemur")
  expect_sidebar_main_text(3, "fierce lemur")
  app$expect_screenshot(selector = "#layout_3")

  # swap expanded sidebars
  app$
    click(selector = "#main_inner_3 ~ .collapse-toggle")$
    click(selector = "#main_outer_3 ~ .collapse-toggle")$
    wait_for_js(js_sidebar_transition_complete(id = 3, "outer"))$
    expect_values()

  # outer sidebar is revealed
  expect_sidebar_hidden(id = 3, "inner")
  expect_sidebar_shown(id = 3, "outer")

  # change the input value
  app$set_inputs(adjective_3 = "quirky")
  expect_sidebar_main_text(3, "quirky lemur")
  app$expect_screenshot(selector = "#layout_3")
})

# 310-bslib-sidebar-dynamic: test all sidebar toggling methods ----------------
test_that("310-bslib-sidebar-dynamic: test all sidebar toggling methods", {
  withr::local_envvar(list(INCLUDE_INITIAL_SIDEBAR = TRUE))

  app <- AppDriver$new(
    name = "310-bslib-sidebar-toggle-methods",
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

  # Let the output in the sidebar main panel be tab focusable
  app$run_js("document.getElementById('ui_content_0').setAttribute('tabindex', '0')")

  # First tab press enters the main content before sidebars
  key_press("Tab")
  expect_equal(
    app$get_js("document.activeElement.id"),
    "ui_content_0"
  )

  # Next tab enters the input in the inner sidebar
  key_press("Tab")
  expect_equal(
    app$get_js("document.activeElement.id"),
    "animal_0-selectized"
  )

  # Next tab focuses the inner sidebar collapse toggle
  key_press("Tab")
  expect_equal(
    app$get_js("document.activeElement.getAttribute('aria-controls')"),
    "sidebar_inner_0"
  )

  # Clicking this toggle hides the inner sidebar (note we can't directly test
  # the enter/space event handlers because headless chrome uses mobile emulation).
  app$
    click(selector = ":focus")$
    wait_for_js(js_sidebar_transition_complete(id = 0, "inner"))$
    expect_values()

  expect_sidebar_hidden(id = 0, "inner")
  expect_sidebar_shown(id = 0, "outer")

  # Next tab focuses the input in the outer sidebar
  key_press("Tab")
  expect_equal(
    app$get_js("document.activeElement.id"),
    "adjective_0-selectized"
  )

  # Next tab focuses the outer sidebar collapse toggle
  key_press("Tab")
  expect_equal(
    app$get_js("document.activeElement.getAttribute('aria-controls')"),
    "sidebar_outer_0"
  )

  # Clicking this toggle hides the outer sidebar
  app$
    click(selector = ":focus")$
    wait_for_js(js_sidebar_transition_complete(id = 0, "outer"))$
    expect_values()

  expect_sidebar_hidden(id = 0, "inner")
  expect_sidebar_hidden(id = 0, "outer")

  # Next tab focuses on next input in the document
  key_press("Tab")
  expect_equal(
    app$get_js("document.activeElement.id"),
    "add_sidebar"
  )

  # Tabbing back into sidebar moves focus to outer toggle button
  key_press("Tab", shift = TRUE)
  expect_equal(
    app$get_js("document.activeElement.getAttribute('aria-controls')"),
    "sidebar_outer_0"
  )

  # Then to the inner toggle button
  key_press("Tab", shift = TRUE)
  expect_equal(
    app$get_js("document.activeElement.getAttribute('aria-controls')"),
    "sidebar_inner_0"
  )

  # Then into the sidebar main area
  key_press("Tab", shift = TRUE)
  expect_equal(
    app$get_js("document.activeElement.id"),
    "ui_content_0"
  )

  # Trigger server-side expansion of all sidebars
  app$
    click("show_all")$
    wait_for_js(js_sidebar_transition_complete(id = 0, "inner"))$
    wait_for_js(js_sidebar_transition_complete(id = 0, "outer"))$
    expect_values()

  expect_sidebar_shown(id = 0, "inner")
  expect_sidebar_shown(id = 0, "outer")

  # Trigger server-side collapse of inner sidebar
  app$
    click("toggle_last_inner")$
    wait_for_js(js_sidebar_transition_complete(id = 0, "inner"))$
    expect_values()

  expect_sidebar_hidden(id = 0, "inner")
  expect_sidebar_shown(id = 0, "outer")

  # Trigger server-side collapse of outer sidebar
  app$
    click("toggle_last_outer")$
    wait_for_js(js_sidebar_transition_complete(id = 0, "outer"))$
    expect_values()

  expect_sidebar_hidden(id = 0, "inner")
  expect_sidebar_hidden(id = 0, "outer")
})

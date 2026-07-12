library(shinytest2)

# Only take screenshots on mac + r-release to reduce diff noise
expect_screenshot_mac_release <- local({
  release <- jsonlite::fromJSON("https://api.r-hub.io/rversions/resolve/release")$version
  release <- paste0(
    strsplit(release, ".", fixed = TRUE)[[1]][1:2],
    collapse = "."
  )

  is_testing_on_ci <- identical(Sys.getenv("CI"), "true") && testthat::is_testing()
  is_mac_release <- identical(paste0("mac-", release), platform_variant())

  DO_SCREENSHOT <- is_testing_on_ci && is_mac_release
  function(app, ..., threshold = 2) {
    if (!DO_SCREENSHOT) return(invisible(app))

    app$expect_screenshot(..., threshold = threshold)
  }
})

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

js_output_exists <- function(id) {
  selector <- sprintf("#ui_content_%s", id)
  sprintf(
    "$('%s').text().length > 0",
    selector
  )
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
    expect_values_screenshot_args = FALSE,
    screenshot_args = list(
      selector = "viewport",
      delay = 0.5,
      options = list(captureBeyondViewport = FALSE)
    )
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
    wait_for_js(js_sidebar_transition_complete(id = 1))$
    expect_values()

  expect_sidebar_main_text(1, "cuddly giraffe")

  # First sidebar starts open = "open"
  expect_sidebar_shown(id = 1, "inner")
  expect_sidebar_shown(id = 1, "outer")
  expect_screenshot_mac_release(app, selector = "#layout_1")

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
  expect_screenshot_mac_release(app, selector = "#layout_1")

  # Collapse the outer sidebar
  app$
    click(selector = "#main_outer_1 ~ .collapse-toggle")$
    wait_for_js(js_sidebar_transition_complete(id = 1, "outer"))$
    expect_values()

  # both sidebars are collapsed
  expect_sidebar_hidden(id = 1, "inner")
  expect_sidebar_hidden(id = 1, "outer")
  expect_screenshot_mac_release(app, selector = "#layout_1")

  # Expand inner sidebar
  app$
    click(selector = "#main_inner_1 ~ .collapse-toggle")$
    wait_for_js(js_sidebar_transition_complete(id = 1))$
    expect_values()

  # Only inner sidebar is hidden
  expect_sidebar_shown(id = 1, "inner")
  expect_sidebar_hidden(id = 1, "outer")
  expect_screenshot_mac_release(app, selector = "#layout_1")

  # Expand the outer sidebar
  app$
    click(selector = "#main_outer_1 ~ .collapse-toggle")$
    wait_for_js(js_sidebar_transition_complete(id = 1, "outer"))$
    expect_values()

  # both sidebars are shown
  expect_sidebar_shown(id = 1, "inner")
  expect_sidebar_shown(id = 1, "outer")
  expect_screenshot_mac_release(app, selector = "#layout_1")

  # Update both inputs
  app$set_inputs(animal_1 = "panda", adjective_1 = "silly")
  expect_sidebar_main_text(1, "silly panda")

  # Add second sidebar -----
  app$
    click("add_sidebar")$
    wait_for_js(js_output_exists(id = 2))$
    expect_values()
  expect_sidebar_main_text(2, "elegant jaguar")

  # both sidebars are hidden because open = "closed"
  expect_sidebar_hidden(id = 2, "inner")
  expect_sidebar_hidden(id = 2, "outer")
  expect_screenshot_mac_release(app, selector = "#layout_2")

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
  expect_screenshot_mac_release(app, selector = "#layout_2")

  # Switch to mobile app size, using iPhone 13 width, extra long to ensure that
  # all layouts are fully visible
  app$set_window_size(390, 1600)


  expect_screenshot_mac_release(app, selector = "#layout_2")

  # Add third sidebar -----
  app$
    click("add_sidebar")$
    wait_for_js(js_output_exists(id = 3))$
    # sidebar is closed immediately upon adding when open = "desktop"
    wait_for_js(js_sidebar_transition_complete(id = 3))$
    expect_values()

  expect_sidebar_main_text(3, "fierce koala")

  # both sidebars are hidden because open = "closed"
  expect_sidebar_hidden(id = 3, "inner")
  expect_sidebar_hidden(id = 3, "outer")
  expect_screenshot_mac_release(app, selector = "#layout_3")

  # reveal inner sidebar
  app$
    click(selector = "#main_inner_3 ~ .collapse-toggle")$
    wait_for_js(js_sidebar_transition_complete(id = 3, "inner"))$
    expect_values()

  # inner sidebar is revealed
  expect_sidebar_shown(id = 3, "inner")
  expect_sidebar_hidden(id = 3, "outer")

  # change the input value
  app$set_inputs(animal_3 = "lemur")
  expect_sidebar_main_text(3, "fierce lemur")
  expect_screenshot_mac_release(app, selector = "#layout_3")

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
  expect_screenshot_mac_release(app, selector = "#layout_3")
})

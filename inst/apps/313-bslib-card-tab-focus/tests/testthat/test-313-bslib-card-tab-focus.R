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

if (
  is_mac_release &&
  length(dir("_snaps")) > 0 &&
  !identical(dir("_snaps"), platform_variant())
) {
  stop("Outdated snaps folder found!")
}

source(system.file("helpers", "keyboard.R", package = "shinycoreci"))

expect_focus <- function(app, selector) {
  js <- sprintf(
    "document.activeElement == document.querySelector('%s')",
    selector
  )
  expect_true(app$get_js(!!js))
  invisible(app)
}

expect_card_full_screen <- function(app, id) {
  id <- sub("^#", "", id)
  app$wait_for_js('document.body.matches(".bslib-has-full-screen")')
  # The expected card is expanded in full screen mode
  expect_equal(
    app$get_js(sprintf(
     "document.getElementById('%s').getAttribute('data-full-screen')",
      id
    )),
    "true"
  )
  # Only one card is expanded to full screen
  expect_equal(
    app$get_js("document.querySelectorAll('.bslib-card[data-full-screen=\"true\"]').length"),
    1
  )
  # The overlay (behind card and above UI) is present
  expect_equal(
    app$get_js("document.querySelectorAll('#bslib-full-screen-overlay').length"),
    1
  )

  interior_focus <- app$get_js(
    sprintf("document.getElementById('%s').contains(document.activeElement)", id)
  )
  if (interior_focus) {
    # yeah this doesn't do anything but count the interior focus expectation
    expect_true(interior_focus)
  } else {
    expect_focus(app, paste0("#", id))
  }
  invisible(app)
}

expect_no_full_screen <- function(app, id = NULL) {
  app$wait_for_js('!document.body.matches(".bslib-has-full-screen")')
  expect_equal(
    app$get_js("document.querySelectorAll('.bslib-card[data-full-screen=\"true\"]').length"),
    0
  )
  if (is.null(id)) return(invisible(app))

  expect_equal(
    app$get_js(sprintf(
      "document.getElementById('%s').getAttribute('data-full-screen')",
      id
    )),
    "false"
  )

  invisible(app)
}

app_reset_no_full_screen <- function(app) {
  # reset focus to "neutral focus zone" (just an uninvolved element)
  withr::defer(app$run_js("document.getElementById('neutral-focus-zone').focus()"))

  is_full_screen <- app$get_js("document.body.matches('.bslib-has-full-screen')")

  if (!is_full_screen) {
    return(invisible(app))
  }

  app$
    click(selector = "#bslib-full-screen-overlay")$
    wait_for_js('!document.body.matches(".bslib-has-full-screen")')
}

app_card_full_screen_enter <- function(app, id) {
  id <- sub("^#", "", id)
  app$click(selector = sprintf("#%s > * > .bslib-full-screen-enter", id))
  expect_card_full_screen(app, id)
  invisible(app)
}

app_card_full_screen_exit <- function(
  app,
  method = c("click button", "click overlay", "escape", "enter button", "space button")
) {
  key_press <- key_press_factory(app)

  method <- match.arg(method)
  switch(method,
    "click button" = app$click(selector = ".bslib-full-screen-exit"),
    "click overlay" = app$click(selector = "#bslib-full-screen-overlay"),
    "escape" = key_press_and_sleep("Escape"),
    "enter button" = {
      app$run_js("document.querySelector('.bslib-full-screen-exit').focus()")
      key_press("Enter")
    },
    "space button" = {
      app$run_js("document.querySelector('.bslib-full-screen-exit').focus()")
      key_press_and_sleep("Space")
    }
  )

  expect_no_full_screen(app)
  invisible(app)
}

js_computed_display <- function(selector) {
  sprintf(
    "window.getComputedStyle(document.querySelector('%s')).display",
    selector
  )
}

expect_display <- function(app, value, selector) {
  expect_equal(app$get_js(!!js_computed_display(selector)), value)
  invisible(app)
}

# Setup App  -----------------------------------------------------------
app <- AppDriver$new(
  name = "313-bslib-card-tab-focus",
  variant = platform_variant(),
  height = 800,
  width = 1200,
  seed = 20230517,
  view = interactive(),
  options = list(bslib.precompiled = FALSE),
  expect_values_screenshot_args = FALSE,
  screenshot_args = list(selector = "viewport", delay = 0.5)
)
withr::defer(app$stop())

key_press <- key_press_factory(app)
key_press_and_sleep <- function(..., sleep = 0.25) {
  key_press(...)
  Sys.sleep(sleep)
}
test_that("initial state, no cards are expanded", {
  expect_no_full_screen(app)
})

# First card, no inputs --------------------------------------------
test_that("fullscreen card without internal focusable elements", {
  app_reset_no_full_screen(app)

  app_card_full_screen_enter(app, "card-no-inputs")
  if (DO_SCREENSHOT) app$expect_screenshot()

  # Tabbing moves to exit button
  key_press_and_sleep("Tab")
  expect_focus(app, ".bslib-full-screen-exit")

  # Tabbing again stays on the exit button
  key_press_and_sleep("Tab")
  expect_focus(app, ".bslib-full-screen-exit")

  # Tabbing with shift stays on the exit button
  key_press_and_sleep("Tab", shift = TRUE)
  expect_focus(app, ".bslib-full-screen-exit")

  # Exit full screen
  key_press_and_sleep("Enter")
  expect_no_full_screen(app, id = "card-no-inputs")
})

# Test enter/exit methods ------------------------------------------
test_that("fullscreen card all exit methods", {
  app_reset_no_full_screen(app)

  app_card_full_screen_enter(app, "card-no-inputs")
  app_card_full_screen_exit(app, "click overlay")

  app_card_full_screen_enter(app, "card-no-inputs")
  app_card_full_screen_exit(app, "click button")

  app_card_full_screen_enter(app, "card-no-inputs")
  app_card_full_screen_exit(app, "escape")

  app_card_full_screen_enter(app, "card-no-inputs")
  app_card_full_screen_exit(app, "space button")

  app_card_full_screen_enter(app, "card-no-inputs")
  app_card_full_screen_exit(app, "enter button")
})

# Second card with inputs ------------------------------------------
test_that("fullscreen card with inputs and interior cards", {
  app_reset_no_full_screen(app)

  app_card_full_screen_enter(app, "card-with-inputs")
  if (DO_SCREENSHOT) app$expect_screenshot()

  # Tabbing moves to first input
  key_press_and_sleep("Tab")
  expect_focus(app, "#letter-selectized")

  # Tabbing backwards moves to exit button
  key_press_and_sleep("Tab", shift = TRUE)
  expect_focus(app, ".bslib-full-screen-exit")

  # Tabbing backwards moves to last input
  key_press_and_sleep("Tab", shift = TRUE)
  expect_focus(app, "#go")

  # Tabbing forwards returns to exit button
  key_press_and_sleep("Tab")
  expect_focus(app, ".bslib-full-screen-exit")

  # If focus moves outside of card (somehow), tabbing returns focus to card
  app$run_js("document.getElementById('neutral-focus-zone').focus()")
  expect_focus(app, "#neutral-focus-zone")
  key_press_and_sleep("Tab")
  expect_focus(app, "#card-with-inputs")

  # Internal expand icons are hidden
  expect_display(app, "none", "#card-with-inputs-left .bslib-full-screen-enter")
  expect_display(app, "none", "#card-with-inputs-right .bslib-full-screen-enter")

  # Exit full screen
  app_card_full_screen_exit(app, "escape")
})

# Interior card with inputs left (Tab forwards) --------------------
test_that("fullscreen interior card with inputs (forward tab cycle)", {
  app_reset_no_full_screen(app)

  app_card_full_screen_enter(app, "card-with-inputs-left")
  if (DO_SCREENSHOT) app$expect_screenshot()

  # Tab through inputs
  key_press_and_sleep("Tab")
  expect_focus(app, "#letter-selectized")
  key_press_and_sleep("Tab")
  expect_focus(app, "#letter2-selectized")
  key_press_and_sleep("Escape")
  key_press_and_sleep("Tab")
  expect_focus(app, "#dates input:first-child")
  key_press_and_sleep("Tab")
  expect_focus(app, "#dates input:last-child")
  key_press_and_sleep("Escape")
  key_press_and_sleep("Tab")
  expect_focus(app, ".bslib-full-screen-exit")
  key_press_and_sleep("Tab")
  expect_focus(app, "#letter-selectized")

  expect_card_full_screen(app, "card-with-inputs-left")

  app_card_full_screen_exit(app, "click overlay")
})

# Escape while select box is open -----------------------------------
test_that("escape while select box open exits select, not full screen", {
  app_reset_no_full_screen(app)

  app_card_full_screen_enter(app, "card-with-inputs-left")

  # Tab to expand select box
  key_press_and_sleep("Tab")
  expect_focus(app, "#letter-selectized")

  # Escape doesn't leave full screen
  key_press_and_sleep("Escape")

  if (app$get_js("document.activeElement.tagName === 'BODY'")) {
    # In this browser, the select box is closed, but focus is lost
    expect_true(
      app$get_js('document.body.classList.contains("bslib-has-full-screen")')
    )
    key_press_and_sleep("Tab")
    expect_card_full_screen(app, "card-with-inputs-left")
    skip("Escape on selectize closes select box, but focus moves to body")
  }

  expect_card_full_screen(app, "card-with-inputs-left")

  # Tab to expand next select box
  key_press_and_sleep("Tab")
  expect_focus(app, "#letter2-selectized")
  # Escape doesn't leave full screen here either
  key_press_and_sleep("Escape")
  expect_card_full_screen(app, "card-with-inputs-left")

  app_card_full_screen_exit(app, "click overlay")
})

# Interior focus is retained ----------------------------------
test_that("interior focus is retains when entering full screen", {
  app_reset_no_full_screen(app)

  # focus on an interior element should be maintained. This happens because
  # we are triggering the full screen programmatically, in practice focus moves
  # when users click. This test is still valuable for future server-side methods
  app$run_js("document.getElementById('word').focus()")
  expect_focus(app, "#word")

  app_card_full_screen_enter(app, "card-with-inputs-right")
  expect_focus(app, "#word")

  app_card_full_screen_exit(app)
  expect_focus(app, "#word")
})

# Interior card with inputs right (Tab backwards) --------------
test_that("fullscreen interior card with inputs (backward tab cycle)", {
  app_reset_no_full_screen(app)

  app$run_js("document.body.focus()")
  app_card_full_screen_enter(app, "card-with-inputs-right")
  expect_focus(app, "#card-with-inputs-right")
  if (DO_SCREENSHOT) app$expect_screenshot()

  key_press_and_sleep("Tab")
  key_press_and_sleep("Tab")
  expect_focus(app, "#word")

  key_press_and_sleep("Tab", shift = TRUE)
  expect_true(app$get_js( # sliders are weird inputs
    "document.getElementById('slider-label').nextElementSibling.contains(document.activeElement)"
  ))

  key_press_and_sleep("Tab", shift = TRUE)
  expect_focus(app, ".bslib-full-screen-exit")

  key_press_and_sleep("Tab", shift = TRUE)
  expect_focus(app, "#sentence")

  key_press_and_sleep("Tab", shift = TRUE)
  expect_focus(app, "#word")

  app_card_full_screen_exit(app, "click button")
  expect_focus(app, "#word")
})

# Final card ------------------------------------------------------
test_that("fullscreen card with large plotly plot", {
  app_reset_no_full_screen(app)

  app$run_js("document.getElementById('card-with-plot').scrollIntoView(true)")

  app_card_full_screen_enter(app, "card-with-plot")
  # no screenshot here, it's too volatile

  key_press_and_sleep("Tab")
  expect_focus(app, "#search")

  key_press_and_sleep("Tab")
  expect_true(app$get_js( # moves into plotly plot
    "document.querySelector('.plotly').contains(document.activeElement)"
  ))

  key_press("Tab", shift = TRUE)
  key_press("Tab", shift = TRUE)
  expect_focus(app, ".bslib-full-screen-exit")
  app_card_full_screen_exit(app, "enter button")
})

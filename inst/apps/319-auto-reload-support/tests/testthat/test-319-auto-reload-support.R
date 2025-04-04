library(shinytest2)

app_path <- function(...) {
  rprojroot::find_package_root_file(
    "inst",
    "apps",
    "319-auto-reload-support",
    ...
  )
}

click_and_wait_for_reload <- function(app, id) {
  b <- app$get_chromote_session()
  p <- b$Runtime$evaluate(
    sprintf("document.querySelector('#%s').click()", id),
    wait_ = FALSE
  )$then(function(value) {
    b$Page$loadEventFired(wait_ = FALSE)
  })
  b$wait_for(p)
}

# app.R variant ----------------------------------------------------------------
test_that("Test that auto-reload works with app.R", {
  app <- AppDriver$new(
    app_dir = app_path("01-app-dot-R"),
    variant = platform_variant(),
    height = 800,
    width = 1200,
    seed = 20250224,
    view = interactive(),
    options = list(bslib.precompiled = FALSE, shiny.autoreload = TRUE),
    expect_values_screenshot_args = FALSE,
    screenshot_args = list(selector = "viewport", delay = 0.5)
  )
  withr::defer(app$stop())

  app$wait_for_idle()
  expect_equal(app$get_text("#title"), "Test start")

  click_and_wait_for_reload(app, "update_title")

  expect_equal(app$get_text("#title"), "Test passed")
})

# ui/server variant ------------------------------------------------------------
test_that("Test that auto-reload works with ui/server", {
  app <- AppDriver$new(
    app_dir = app_path("02-ui-server"),
    variant = platform_variant(),
    height = 800,
    width = 1200,
    seed = 20250224,
    view = interactive(),
    options = list(bslib.precompiled = FALSE, shiny.autoreload = TRUE),
    expect_values_screenshot_args = FALSE,
    screenshot_args = list(selector = "viewport", delay = 0.5)
  )
  withr::defer(app$stop())

  app$wait_for_idle()
  expect_equal(app$get_text("#ui_test"), "UI test start")
  expect_equal(app$get_text("#server_test"), "Server test start")
  expect_equal(app$get_text("#global_test"), "Global test start")

  click_and_wait_for_reload(app, "update_files")

  app$wait_for_js("document.querySelector('#server_test').innerText !== '';")

  expect_equal(app$get_text("#ui_test"), "UI test passed")
  expect_equal(app$get_text("#server_test"), "Server test passed")
  expect_equal(app$get_text("#global_test"), "Global test start")
})

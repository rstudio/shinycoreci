library(shinytest2)

withr::local_envvar(list(SIDEBAR_TRANSITION_TIME = "1s"))

app <- AppDriver$new(
  name = "312-bslib-sidebar-resize",
  variant = platform_variant(),
  height = 1600,
  width = 1200,
  view = interactive(),
  options = list(bslib.precompiled = FALSE),
  expect_values_screenshot_args = FALSE
)

withr::defer(app$stop())

# STATIC PAGE ================================================================
test_that("Resizing sidebars on page with ggplot2 plots", {
  # collapse static shared sidebar --------------------------------------------
  expect_sidebar_transition(app, "shared", "static", open_end = "closed")

  # collapse static local sidebar ---------------------------------------------
  expect_sidebar_transition(app, "local", "static", open_end = "closed")

  # expand static shared sidebar ----------------------------------------------
  expect_sidebar_transition(app, "shared", "static", open_end = "open")
})

# SWITCH TO WIDGET PAGE ======================================================
test_that("Resizing sidebars on page with shiny-backed htmlwidgets", {
  app$
    click(selector = '.nav-link[data-value="Widget"]')$
    wait_for_js("$('#plot_widget_local:visible .svg-container').length > 0")$
    run_js("Shiny.setInputValue('open_sidebar_shared', Date.now())")$
    wait_for_js(js_sidebar_transition_complete("sidebar-shared"))

  # now we repeat all of the same tests above, except that the widget resizing
  # won't trigger a 'shiny:value' event.

  # collapse widget shared sidebar --------------------------------------------
  expect_sidebar_transition(app, "shared", "widget", open_end = "closed")

  # collapse widget local sidebar ---------------------------------------------
  expect_sidebar_transition(app, "local", "widget", open_end = "closed")

  # expand widget shared sidebar ----------------------------------------------
  expect_sidebar_transition(app, "shared", "widget", open_end = "open")
})

# SWITCH TO CLIENT PAGE ======================================================
test_that("Resizing sidebars on page with static htmlwidgets", {
  app$
    click(selector = '.nav-link[data-value="Client"]')$
    wait_for_js("$('#plot_client_local:visible .svg-container').length > 0")$
    run_js("Shiny.setInputValue('open_sidebar_shared', Date.now())")$
    wait_for_js(js_sidebar_transition_complete("sidebar-shared"))

  # now we repeat all of the same tests above, except that the widget resizing
  # won't trigger a 'shiny:value' event.

  # collapse widget shared sidebar --------------------------------------------
  expect_sidebar_transition(app, "shared", "client", open_end = "closed")

  # collapse widget local sidebar ---------------------------------------------
  expect_sidebar_transition(app, "local", "client", open_end = "closed")

  # expand widget shared sidebar ----------------------------------------------
  expect_sidebar_transition(app, "shared", "client", open_end = "open")
})

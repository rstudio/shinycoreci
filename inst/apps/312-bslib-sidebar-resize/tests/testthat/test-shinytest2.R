library(shinytest2)

expect_sidebar_hidden_factory <- function(app) {
  function(id) {
    state <- app$get_js(js_sidebar_state(id = id))
    expect_true("sidebar-collapsed" %in% state$layout_classes)
    expect_equal(state$content_display, "none")
    expect_true(state$sidebar_hidden)
  }
}

expect_sidebar_shown_factory <- function(app) {
  function(id) {
    state <- app$get_js(js_sidebar_state(id = id))
    expect_false("sidebar-collapsed" %in% state$layout_classes)
    expect_false(identical(state$content_display, "none"))
    expect_false(state$sidebar_hidden)
  }
}

js_sidebar_transition_complete <- function(id) {
  sprintf(
    "!document.getElementById('%s').parentElement.classList.contains('transitioning');",
    id
  )
}

js_sidebar_state <- function(id) {
  sprintf(
    "(function() {
      return {
      layout_classes: Array.from(document.getElementById('%s').closest('.bslib-sidebar-layout').classList),
      content_display: window.getComputedStyle(document.querySelector('#%s .sidebar-content')).getPropertyValue('display'),
      sidebar_hidden: document.getElementById('%s').hidden
    }})();",
    id, id, id
  )
}

js_element_width <- function(selector) {
  sprintf(
    "document.querySelector('%s').getBoundingClientRect().width;",
    selector
  )
}

# Gather width measurements of plots during the sidebar transition
#
# 1. Measures the `initial` width of plots prior to transition
# 2. Clicks the sidebar toggle
# 3. Samples width of plots `during` transition
# 4. Waits for transition to complete
# 5. Measures the `final` width of plots after transition
# 6. Captures updated shiny `outputs` during the measurement period
watch_sidebar_transition <- function(
  app,
  sidebar = c("shared", "local"),
  page = c("static", "widget")
) {
  sidebar <- match.arg(sidebar)
  page <- match.arg(page)

  id_sidebar <- if (sidebar == "shared") "sidebar-shared" else paste0("sidebar-local-", page)
  sel_plot <- function(which = c("shared", "local")) {
    plot_container <-
      if (page == "static") {
        "img"
      } else {
        ".plot-container > .svg-container"
      }
    paste0("#plot_", page, "_", which, " > ", plot_container)
  }
  sel_plot_img_local <- sel_plot("local")
  sel_plot_img_shared <- sel_plot("shared")

  initial <- list(
    local = app$get_js(js_element_width(sel_plot_img_local)),
    shared = app$get_js(js_element_width(sel_plot_img_shared))
  )

  during <- list(local = c(), shared = c())

  app$run_js("
if (!window.updatedOutputs) {
  $(document).on('shiny:value', function(event) {
    window.updatedOutputs.push(event.target.id);
  })
}
window.updatedOutputs = [];
")
  app$click(selector = sprintf("#%s + .collapse-toggle", id_sidebar))

  while (!app$get_js(js_sidebar_transition_complete(id_sidebar))) {
    Sys.sleep(0.1)
    during$local <- c(during$local, app$get_js(js_element_width(sel_plot_img_local)))
    during$shared <- c(during$shared, app$get_js(js_element_width(sel_plot_img_shared)))
  }

  if (page == "static") {
    app$wait_for_js("window.updatedOutputs.length > 0")
    Sys.sleep(0.25)
  } else {
    # widget plots don't trigger shiny:value events, so we just have to wait
    Sys.sleep(1)
  }

  outputs <- app$get_js("window.updatedOutputs")
  final <- list(
    local = app$get_js(js_element_width(sel_plot_img_local)),
    shared = app$get_js(js_element_width(sel_plot_img_shared))
  )

  list(
    initial = initial,
    during = during,
    final = final,
    outputs = unlist(outputs)
  )
}

# 312-bslib-sidebar-resize ----------------------------------------------------
test_that("312-bslib-sidebar-resize", {
  app <- AppDriver$new(
    name = "312-bslib-sidebar-resize",
    variant = platform_variant(),
    height = 1600,
    width = 1200,
    view = interactive(),
    options = list(bslib.precompiled = FALSE),
    expect_values_screenshot_args = FALSE
  )

  expect_sidebar_hidden <- expect_sidebar_hidden_factory(app)
  expect_sidebar_shown <- expect_sidebar_shown_factory(app)

  # STATIC PAGE ================================================================

  # collapse static shared sidebar --------
  close_static_shared <- watch_sidebar_transition(
    app,
    sidebar = "shared",
    page = "static"
  )

  expect_sidebar_hidden("sidebar-shared")

  # plot output image size changed during collapse for both plots
  expect_gt(length(unique(close_static_shared$during$local)), 1)
  expect_gt(length(unique(close_static_shared$during$shared)), 1)

  # plot output image size was growing during transition
  expect_gt(min(close_static_shared$during$local), close_static_shared$initial$local)
  expect_gt(min(close_static_shared$during$shared), close_static_shared$initial$shared)

  # both plots updated at the end of the transition
  expect_setequal(close_static_shared$outputs, c("plot_static_local", "plot_static_shared"))

  # collapse static local sidebar --------
  close_static_local <- watch_sidebar_transition(
    app,
    sidebar = "local",
    page = "static"
  )

  expect_sidebar_hidden("sidebar-local-static")

  # plot output image size changed during collapse for local plot only
  expect_gt(length(unique(close_static_local$during$local)), 1)
  expect_equal(length(unique(close_static_local$during$shared)), 1)

  # plot output image size was growing during transition for local only
  expect_gt(min(close_static_local$during$local), close_static_local$initial$local)
  expect_equal(unique(close_static_local$during$shared), close_static_local$initial$shared)

  # local plot updated at the end of the transition
  expect_equal(close_static_local$outputs, "plot_static_local")

  # expand static shared sidebar --------
  open_static_shared <- watch_sidebar_transition(
    app,
    sidebar = "shared",
    page = "static"
  )

  expect_sidebar_shown("sidebar-shared")

  # plot output image size changed during expand for both plots
  expect_gt(length(unique(open_static_shared$during$local)), 1)
  expect_gt(length(unique(open_static_shared$during$shared)), 1)

  # plot output image size was shrinking during transition
  expect_lt(max(open_static_shared$during$local), open_static_shared$initial$local)
  expect_lt(max(open_static_shared$during$shared), open_static_shared$initial$shared)

  # both plots updated at the end of the transition
  expect_setequal(open_static_shared$outputs, c("plot_static_local", "plot_static_shared"))

  # SWITCH TO WIDGET PAGE ======================================================
  app$
    click(selector = '.nav-link[data-value="Widget"]')$
    wait_for_js("document.getElementById('js-plotly-tester') ? true : false")

  # now we repeat all of the same tests above, except that the widget resizing
  # won't trigger a 'shiny:value' event.

  # collapse widget shared sidebar --------
  close_widget_shared <- watch_sidebar_transition(
    app,
    sidebar = "shared",
    page = "widget"
  )

  expect_sidebar_hidden("sidebar-shared")

  # plot output image size changed during collapse for both plots
  expect_gt(length(unique(close_widget_shared$during$local)), 1)
  expect_gt(length(unique(close_widget_shared$during$shared)), 1)

  # plot output image size was growing during transition
  expect_gt(min(close_widget_shared$during$local), close_widget_shared$initial$local)
  expect_gt(min(close_widget_shared$during$shared), close_widget_shared$initial$shared)

  # collapse widget local sidebar --------
  close_widget_local <- watch_sidebar_transition(
    app,
    sidebar = "local",
    page = "widget"
  )

  expect_sidebar_hidden("sidebar-local-widget")

  # plot output image size changed during collapse for local plot only
  expect_gt(length(unique(close_widget_local$during$local)), 1)
  expect_equal(length(unique(close_widget_local$during$shared)), 1)

  # plot output image size was growing during transition for local only
  expect_gt(min(close_widget_local$during$local), close_widget_local$initial$local)
  expect_equal(unique(close_widget_local$during$shared), close_widget_local$initial$shared)

  # expand widget shared sidebar --------
  open_widget_shared <- watch_sidebar_transition(
    app,
    sidebar = "shared",
    page = "widget"
  )

  expect_sidebar_shown("sidebar-shared")

  # plot output image size changed during expand for both plots
  expect_gt(length(unique(open_widget_shared$during$local)), 1)
  expect_gt(length(unique(open_widget_shared$during$shared)), 1)

  # plot output image size was shrinking during transition
  expect_lt(max(open_widget_shared$during$local), open_widget_shared$initial$local)
  expect_lt(max(open_widget_shared$during$shared), open_widget_shared$initial$shared)

})

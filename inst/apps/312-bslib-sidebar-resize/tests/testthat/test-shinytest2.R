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
  page = c("static", "widget", "client")
) {
  sidebar <- match.arg(sidebar)
  page <- match.arg(page)

  id_sidebar <- switch(
    sidebar,
    shared = "sidebar-shared",
    paste0("sidebar-local-", page)
  )

  sel_plot <- function(which = c("shared", "local" , "client")) {
    plot_container <- switch(
      page,
      static = "img",
      widget = ".plot-container > .svg-container",
      client = ".plotly > .plot-container > .svg-container"
    )
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

  cat("\n----- Recording", sidebar, "sidebar on", page, "page transition -----")
  cat_item <- function(which) {
    value <- get(which)
    cat("\n", which, ":")
    cat("\n  shared: ", paste(value[["shared"]], collapse = ", "))
    cat("\n  local:  ", paste(value[["local"]], collapse = ", "))
  }
  cat_item("initial")
  cat_item("during")
  cat_item("final")
  cat_item("outputs")
  cat("\n----------------------------------------------\n\n")

  # we only need unique observations between initial and final
  during$local <- unique(during$local)
  during$shared <- unique(during$shared)

  list(
    initial = initial,
    during = during,
    final = final,
    outputs = unlist(outputs)
  )
}

expect_sidebar_transition <- function(
  app,
  sidebar = c("shared", "local"),
  page = c("static", "widget", "client"),
  open_end = c("open", "closed")
) {
  sidebar <- match.arg(sidebar)
  page <- match.arg(page)
  open_end <- match.arg(open_end)

  expect_sidebar_shown <- expect_sidebar_shown_factory(app)
  expect_sidebar_hidden <- expect_sidebar_hidden_factory(app)

  sidebar_id <-
    if (sidebar == "shared") {
      "sidebar-shared"
    } else {
      paste0("sidebar-local-", page)
    }

  will_transition <- c("local", if (sidebar == "shared") "shared")
  change_dir <- if (open_end == "open") "expand" else "collapse"

  # test sidebar state before transition
  switch(
    open_end,
    open = expect_sidebar_hidden(sidebar_id),
    closed = expect_sidebar_shown(sidebar_id)
  )

  # toggle the sidebar and measure the transition
  res <- watch_sidebar_transition(app, sidebar = sidebar, page = page)

  # test sidebar state after transition
  switch(
    open_end,
    open = expect_sidebar_shown(sidebar_id),
    closed = expect_sidebar_hidden(sidebar_id)
  )

  # Plot output size changes during the transition
  if ("local" %in% will_transition) {
    expect_gt(
      length(res$during$local),
      expected = 1,
      label = "local plot output size changes during transition"
    )
  }

  if ("shared" %in% will_transition) {
    expect_gt(
      length(res$during$shared),
      expected = 1,
      label = "shared plot output size changes during transition"
    )
  }

  expect_plot_grows <- function(plot = c("local", "shared")) {
    plot <- match.arg(plot)


    # initial size is a lower bound, plots grow as sidebar collapses
    expect_gt(
      min(res$during[[plot]]),
      res$initial[[!!plot]],
      label = sprintf("minimum %s plot output size during transition", plot)
    )
    has_size_changes <- expect_true(
      length(res$during[[plot]]) > 1,
      label = sprintf("has %s plot output size changes during transition", plot)
    )
    if (has_size_changes) {
      expect_true(
        all(diff(res$during[[plot]]) > 0),
        label = sprintf("%s plot output size was growing during transition", plot)
      )
    }
  }

  expect_plot_shrinks <- function(plot = c("local", "shared")) {
    plot <- match.arg(plot)

    # initial size is the upper bound, plots shrink as sidebar expands
    expect_lt(
      max(res$during[[plot]]),
      res$initial[[!!plot]],
      label = sprintf("maximum %s plot output size during transition", plot)
    )
    has_size_changes <- expect_true(
      length(res$during[[plot]]) > 1,
      label = sprintf("has %s plot output size changes during transition", plot)
    )
    if (has_size_changes) {
      expect_true(
        all(diff(res$during[[plot]]) < 0),
        label = sprintf("%s plot output size was growing during transition", plot)
      )
    }
  }

  # plot output image size was growing/shrinking during transition
  if ("local" %in% will_transition) {
    switch(
      open_end,
      open = expect_plot_shrinks("local"),
      closed = expect_plot_grows("local")
    )
  } else {
    expect_equal(
      res$during$local,
      res$initial$local,
      label = "local plot output size did not change during transition"
    )
  }

  if ("shared" %in% will_transition) {
    switch(
      open_end,
      open = expect_plot_shrinks("shared"),
      closed = expect_plot_grows("shared")
    )
  } else {
    expect_equal(
      res$during$shared,
      res$initial$shared,
      label = "shared plot output size did not change during transition"
    )
  }

  if (page == "static") {
    # plots update at the end of the transition
    expected_updates <- paste0("plot_static_", will_transition)
    expect_setequal(res$outputs, !!expected_updates)
  }
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

  # STATIC PAGE ================================================================

  withCallingHandlers({
  # collapse static shared sidebar --------------------------------------------
  expect_sidebar_transition(app, "shared", "static", open_end = "closed")

  # collapse static local sidebar ---------------------------------------------
  expect_sidebar_transition(app, "local", "static", open_end = "closed")

  # expand static shared sidebar ----------------------------------------------
  expect_sidebar_transition(app, "shared", "static", open_end = "open")

  # SWITCH TO WIDGET PAGE ======================================================
  app$
    click(selector = '.nav-link[data-value="Widget"]')$
    wait_for_js("$('#plot_widget_local:visible .svg-container').length > 0")

  # now we repeat all of the same tests above, except that the widget resizing
  # won't trigger a 'shiny:value' event.

  # collapse widget shared sidebar --------------------------------------------
  expect_sidebar_transition(app, "shared", "widget", open_end = "closed")

  # collapse widget local sidebar ---------------------------------------------
  expect_sidebar_transition(app, "local", "widget", open_end = "closed")

  # expand widget shared sidebar ----------------------------------------------
  expect_sidebar_transition(app, "shared", "widget", open_end = "open")

  # SWITCH TO CLIENT PAGE ======================================================
  app$
    click(selector = '.nav-link[data-value="Client"]')$
    wait_for_js("$('#plot_client_local:visible .svg-container').length > 0")

  # now we repeat all of the same tests above, except that the widget resizing
  # won't trigger a 'shiny:value' event.

  # collapse widget shared sidebar --------------------------------------------
  expect_sidebar_transition(app, "shared", "client", open_end = "closed")

  # collapse widget local sidebar ---------------------------------------------
  expect_sidebar_transition(app, "local", "client", open_end = "closed")

  # expand widget shared sidebar ----------------------------------------------
  expect_sidebar_transition(app, "shared", "client", open_end = "open")
  }, error = function(err) {
    cat("\n\n\n==== TEST FAILED ================================")
    cat("\nError received: ", conditionMessage(err))
    cat("\nPrinting logs...")
    print(app$get_logs())
    cat("\nsaving screenshot...")
    app$expect_screenshot(selector = "viewport")
    cat("\nscreenshot saved...")
  })
})

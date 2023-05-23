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

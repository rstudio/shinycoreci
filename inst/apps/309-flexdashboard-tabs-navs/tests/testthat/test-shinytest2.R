library(shinytest2)

is_element_visible <- function(selector) {
  sprintf("$('%s:visible').length > 0", selector)
}

is_test_element_visible <- function(test_id) {
  is_element_visible(sprintf('[data-test-id="%s"]', test_id))
}

expect_test_element_visible <- function(app, test_id) {
  expect_true(app$get_js(is_test_element_visible(!!test_id)))
  return(invisible(app))
}

expect_test_element_hidden <- function(app, test_id) {
  expect_false(app$get_js(is_test_element_visible(!!test_id)))
  return(invisible(app))
}

for (bs_version in 3:5) {
  test_that(paste0("309-flexdashboard-tabs-navs with BS", bs_version), {
    app <- AppDriver$new(
      name = "309-flexdashboard-tabs-navs",
      seed = 62868,
      height = 1292,
      width = 798,
      view = interactive(),
      render_args = list(output_options = list(theme = list(version = bs_version)))
    )

    app$wait_for_idle()
    app$wait_for_js(is_test_element_visible("Page 1"))

    expect_test_element_visible(app, "Page 1")
    expect_test_element_visible(app, "Tab 1-1a")
    expect_test_element_visible(app, "Tab 1-2a")
    for (tab in c("Tab 1-1a", "Tab 1-2a")) {
      expect_test_element_visible(app, tab)
    }

    expect_test_element_hidden(app, "Page 2")
    expect_test_element_hidden(app, "Page 3")
    for (box in c("Box 2-1", "Box 2-2", "Box 3-1", "Box 3-2")) {
      expect_test_element_hidden(app, box)
    }
    for (tab in c("Tab 1-1b", "Tab 1-2b")) {
      expect_test_element_hidden(app, tab)
    }

    # activate second tabs and check that visibility has switched
    app$
      click(selector = '[data-test-id="Page 1"] .nav-tabs [href$="tab-1-1b"]')$
      wait_for_js(is_test_element_visible("Tab 1-1b"))

    app$
      click(selector = '[data-test-id="Page 1"] .nav-tabs [href$="tab-1-2b"]')$
      wait_for_js(is_test_element_visible("Tab 1-2b"))

    for (tab in c("Tab 1-1a", "Tab 1-2a")) {
      expect_test_element_hidden(app, tab)
    }
    for (tab in c("Tab 1-1b", "Tab 1-2b")) {
      expect_test_element_visible(app, tab)
    }

    # Go to page 2
    app$
      click(selector = ".nav .dropdown .dropdown-toggle")$
      wait_for_js(is_element_visible(".nav .dropdown .dropdown-menu"))$
      click(selector = '.nav .dropdown-item[href$="page-2"]')$
      wait_for_js(is_test_element_visible("Page 2"))

    expect_test_element_visible(app, "Page 2")
    expect_test_element_visible(app, "Box 2-1")
    expect_test_element_visible(app, "Box 2-2")

    expect_test_element_hidden(app, "Page 1")
    expect_test_element_hidden(app, "Page 3")
    for (box in c("Box 1-1", "Box 1-2", "Box 3-1", "Box 3-2")) {
      expect_test_element_hidden(app, box)
    }

    # Go to page 3
    app$
      click(selector = ".nav .dropdown .dropdown-toggle")$
      wait_for_js(is_element_visible(".nav .dropdown .dropdown-menu"))$
      click(selector = '.nav .dropdown-item[href$="page-3"]')$
      wait_for_js(is_test_element_visible("Page 3"))

    expect_test_element_visible(app, "Page 3")
    expect_test_element_visible(app, "Box 3-1")
    expect_test_element_visible(app, "Box 3-2")

    expect_test_element_hidden(app, "Page 1")
    expect_test_element_hidden(app, "Page 2")
    for (box in c("Box 1-1", "Box 1-2", "Box 2-1", "Box 2-2")) {
      expect_test_element_hidden(app, box)
    }
  })
}

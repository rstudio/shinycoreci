library(shinytest2)

is_element_visible <- function(selector) {
  sprintf(
    "(function() {
const br = document.querySelector('%s').getBoundingClientRect()
return br.width > 0 && br.height > 0 && (br.x > 0 || br.y > 0)
})()",
    selector
  )
}

is_test_element_visible <- function(test_id) {
  is_element_visible(sprintf('[data-test-id="%s"]', test_id))
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

    expect_true(app$get_js(is_test_element_visible("Page 1")))
    expect_true(app$get_js(is_test_element_visible("Tab 1-1a")))
    expect_true(app$get_js(is_test_element_visible("Tab 1-2a")))
    for (tab in c("Tab 1-1a", "Tab 1-2a")) {
      expect_true(app$get_js(is_test_element_visible(!!tab)))
    }

    expect_false(app$get_js(is_test_element_visible("Page 2")))
    expect_false(app$get_js(is_test_element_visible("Page 3")))
    for (box in c("Box 2-1", "Box 2-2", "Box 3-1", "Box 3-2")) {
      expect_false(app$get_js(is_test_element_visible(!!box)))
    }
    for (tab in c("Tab 1-1b", "Tab 1-2b")) {
      expect_false(app$get_js(is_test_element_visible(!!tab)))
    }

    # activate second tabs and check that visibility has switched
    app$
      click(selector = '[data-test-id="Page 1"] .nav-tabs [href$="tab-1-1b"]')$
      wait_for_js(is_test_element_visible("Tab 1-1b"))

    app$
      click(selector = '[data-test-id="Page 1"] .nav-tabs [href$="tab-1-2b"]')$
      wait_for_js(is_test_element_visible("Tab 1-2b"))

    for (tab in c("Tab 1-1a", "Tab 1-2a")) {
      expect_false(app$get_js(is_test_element_visible(!!tab)))
    }
    for (tab in c("Tab 1-1b", "Tab 1-2b")) {
      expect_true(app$get_js(is_test_element_visible(!!tab)))
    }

    # Go to page 2
    app$
      click(selector = ".nav .dropdown .dropdown-toggle")$
      wait_for_js(is_element_visible(".nav .dropdown .dropdown-menu"))$
      click(selector = '.nav .dropdown-item[href$="page-2"]')$
      wait_for_js(is_test_element_visible("Page 2"))

    expect_true(app$get_js(is_test_element_visible("Page 2")))
    expect_true(app$get_js(is_test_element_visible("Box 2-1")))
    expect_true(app$get_js(is_test_element_visible("Box 2-2")))

    expect_false(app$get_js(is_test_element_visible("Page 1")))
    expect_false(app$get_js(is_test_element_visible("Page 3")))
    for (box in c("Box 1-1", "Box 1-2", "Box 3-1", "Box 3-2")) {
      expect_false(app$get_js(is_test_element_visible(!!box)))
    }

    # Go to page 3
    app$
      click(selector = ".nav .dropdown .dropdown-toggle")$
      wait_for_js(is_element_visible(".nav .dropdown .dropdown-menu"))$
      click(selector = '.nav .dropdown-item[href$="page-3"]')$
      wait_for_js(is_test_element_visible("Page 3"))

    expect_true(app$get_js(is_test_element_visible("Page 3")))
    expect_true(app$get_js(is_test_element_visible("Box 3-1")))
    expect_true(app$get_js(is_test_element_visible("Box 3-2")))

    expect_false(app$get_js(is_test_element_visible("Page 1")))
    expect_false(app$get_js(is_test_element_visible("Page 2")))
    for (box in c("Box 1-1", "Box 1-2", "Box 2-1", "Box 2-2")) {
      expect_false(app$get_js(is_test_element_visible(!!box)))
    }
  })
}

library(shinytest2)
if (FALSE) library(shinycoreci) # for renv

# Only take screenshots on mac + r-release to reduce diff noise
release <- rversions::r_release()$version
release <- paste0(
  strsplit(release, ".", fixed = TRUE)[[1]][1:2],
  collapse = "."
)

is_testing_on_ci <- identical(Sys.getenv("CI"), "true") &&
  testthat::is_testing()
is_mac_release <- identical(paste0("mac-", release), platform_variant())

DO_SCREENSHOT <- is_testing_on_ci && is_mac_release

expect_js <- function(app, js, label = NULL) {
  expect_true(
    app$wait_for_js(!!js)$get_js(!!js),
    label = label
  )
  invisible(app)
}

shiny_button_value <- function(x) {
  structure(x, class = c("shinyActionButtonValue", "integer"))
}

# Setup App  --------------------------------------------------
app <- AppDriver$new(
  name = "317-nav-insert",
  variant = platform_variant(),
  height = 800,
  width = 1200,
  seed = 20230724,
  view = interactive(),
  options = list(bslib.precompiled = FALSE),
  expect_values_screenshot_args = FALSE,
  screenshot_args = list(selector = "viewport", delay = 0.5)
)
withr::defer(app$stop())

# Setup App state and utility functions ------------------------
test_that("An inserted script runs only once", {
  app$set_inputs(insert_type = "singleton", wait_ = FALSE)$click("do_insert")

  expect_js(
    app,
    "document.querySelectorAll('.tab-pane[data-value=\"One\"]').length === 1"
  )

  expect_equal(app$get_text("#script-count"), "1")
  expect_equal(
    app$get_text('#script-count'),
    app$get_text("#script-count-expected")
  )
})

test_that("A singleton script runs only once", {
  app$set_inputs(insert_type = "singleton", wait_ = FALSE)$click("do_insert")

  expect_js(
    app,
    "document.querySelectorAll('.tab-pane[data-value=\"One\"]').length === 2"
  )

  expect_equal(app$get_text("#script-count"), "1")
  expect_equal(
    app$get_text('#script-count'),
    app$get_text("#script-count-expected")
  )
})

test_that("Scripts in nav and content run once", {
  app$set_inputs(insert_type = "scripts")$click("do_insert")

  expect_js(
    app,
    "document.querySelectorAll('.tab-pane[data-value=\"Two\"]').length === 1"
  )

  expect_equal(app$get_text("#script-count"), "3")
  expect_equal(
    app$get_text('#script-count'),
    app$get_text("#script-count-expected")
  )
})

test_that("htmlwidgets are loaded via nav_insert()", {
  expect_js(
    app,
    "typeof window.LeafletWidget === 'undefined'"
  )

  app$set_inputs(insert_type = "htmlwidgets")$click("do_insert")

  expect_js(
    app,
    "typeof window.LeafletWidget !== 'undefined'"
  )
  expect_js(
    app,
    "document.getElementById('leaflet-1').classList.contains('leaflet')"
  )
  expect_js(
    app,
    "document.getElementById('leaflet-1').classList.contains('html-widget-static-bound')"
  )
})

test_that("input/output in content area", {
  # inputs/outputs don't exist yet
  expect_equal(
    unname(app$get_values(input = c("btn", "slider", "nav_link"))$input),
    list()
  )
  expect_equal(
    unname(app$get_values(output = "debug")$output),
    list()
  )

  app$set_inputs(insert_type = "input_output_content")
  app$click("do_insert")
  app$click("btn")
  app$set_inputs(slider = 5)

  expect_equal(
    app$get_values(input = c("btn", "slider", "nav_link"))$input,
    list(
      btn = shiny_button_value(1L),
      slider = 5
    )
  )

  app$expect_values(
    input = c("btn", "slider", "nav_link"),
    output = "debug"
  )
})

test_that("input/output in nav area", {
  # inputs/outputs don't exist yet
  expect_equal(
    unname(app$get_values(input = c("nav_link"))$input),
    list()
  )
  expect_equal(
    unname(app$get_values(output = "nav_output")$output),
    list()
  )

  app$set_inputs(insert_type = "input_output_nav")
  app$click("do_insert")
  app$click("nav_link")
  app$click("nav_link")

  expect_equal(
    app$get_values(input = c("btn", "slider", "nav_link"))$input,
    list(
      btn = shiny_button_value(1),
      nav_link = shiny_button_value(2),
      slider = 5
    )
  )

  app$expect_values(
    input = c("btn", "slider", "nav_link"),
    output = c("debug", "nav_output")
  )
})

test_that("subapps", {
  app$set_inputs(insert_type = "subapp")
  app$click("do_insert")

  expect_js(
    app,
    'document.querySelector(\'.tab-pane[data-value="Shiny app"] iframe.shiny-frame\') !== null'
  )
  # Wait for inner app to be idle
  expect_js(
    app,
    "document.querySelector('.shiny-frame').contentWindow.document.getElementById('btn') !== null"
  )

  outer_btn_before <- app$get_values()$input$btn

  app$run_js(
    "const iframe = document.querySelector('.shiny-frame').contentWindow.document
    iframe.getElementById('btn').click()"
  )
  Sys.sleep(1)
  inner_debug <- app$get_js(
    "const iframe = document.querySelector('.shiny-frame').contentWindow.document
    iframe.getElementById('debug').innerHTML"
  )
  expect_equal(
    strsplit(inner_debug, "\n")[[1]][1:2],
    c("$btn", "[1] 1")
  )

  # Iframed app is separate from parent app
  expect_equal(
    app$get_values()$input$btn,
    outer_btn_before
  )
})

test_that("web components are connected once", {
  app$set_inputs(insert_type = "init_component")
  app$click("do_insert")

  expect_js(
    app,
    "document.querySelectorAll('init-component').length === 3"
  )

  expect_equal(
    app$get_html("init-component"),
    c(
      "<init-component>Component</init-component>",
      "<init-component>default</init-component>",
      "<init-component>custom init text</init-component>"
    )
  )
})

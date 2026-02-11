library(shinytest2)
library(glue)

# R Version to limit variants ---------------------------------
resolve_r_version <- function(name) {
  rver <- jsonlite::fromJSON(
    glue("https://api.r-hub.io/rversions/resolve/{name}")
  )
  paste0(
    strsplit(rver$version, ".", fixed = TRUE)[[1]][1:2],
    collapse = "."
  )
}

r_release <- resolve_r_version("release")

if (platform_variant() != paste0("mac-", r_release)) {
  skip("Screenshots only on MacOS with R-release")
}

this_platform <- platform_variant()
this_platform <- sub(r_release, "release", this_platform, fixed = TRUE)

# Setup App  --------------------------------------------------
new_app_driver <- function(
  app_dir = testthat::test_path("../../"),
  height = 800,
  width = 1200,
  ...
) {
  AppDriver$new(
    app_dir,
    name = "317-bslib-preset-shiny-dashboard",
    variant = this_platform,
    height = height,
    width = width,
    seed = 2023 * 11 * 13,
    view = interactive(),
    options = list(bslib.precompiled = FALSE),
    screenshot_args = list(
      selector = "viewport",
      delay = 1,
      options = list(captureBeyondViewport = FALSE)
    ),
    ...
  )
}

app <- new_app_driver()
withr::defer(app$stop())

# shinytest2_js <- local({
#   js_file <- system.file("internal", "js", "shiny-tracer.js", package = "shinytest2")
#   js_content <- readLines(js_file)
#   paste(js_content, collapse = "\n")
# })

app_for_variant <- function(app, ..., height = 800, width = 1200) {
  params <- list(...)
  params <- purrr::compact(params)
  params <- purrr::imap(params, function(value, name) sprintf("%s=%s", name, value))
  params <- paste0(params, collapse = "&")

  url <- sprintf("%s?%s", app$get_url(), params)

  new_app_driver(url, height = height, width = width)
}

app_types <- c(
  "navbar",
  "sidebar",
  "fillable-navbar",
  "fillable-sidebar",
  "flow-dash",
  "flow-sidebar",
  "fillable-nested"
)

app_get_toggle_state <- function(app, id) {
  app$get_js(glue("document.getElementById('{id}').checked"))
}

app_set_toggle_state <- function(app, ...) {
  states <- list(...)
  for (id in names(states)) {
    state <- tolower(states[[id]])
    app$run_js(glue(.open = "{{", .close = "}}", "
      const toggle = document.getElementById('{{id}}')
      const changed = toggle.checked !== {{state}}
      if (changed) {
        toggle.checked = {{state}}
        toggle.onchange.call(toggle)
      }
    "))

    app$wait_for_js(glue("document.getElementById('{id}').checked === {state}"))
  }
}

variant_settings <- function(
  app,
  dashboard_toggle = FALSE,
  shadow_toggle = FALSE,
  shadow_sm_toggle = FALSE,
  shadow_lg_toggle = FALSE
) {
  # Both enables desired toggles, while ensuring others are disabled. This
  # doesn't go through `app$set_inputs()` or `app$get_values()` because those
  # don't currently work when the app is reloaded (missing testmode js).
  app_set_toggle_state(
    app,
    dashboard_toggle = dashboard_toggle,
    shadow_toggle = shadow_toggle,
    shadow_sm_toggle = shadow_sm_toggle,
    shadow_lg_toggle = shadow_lg_toggle
  )

  expect_equal(dashboard_toggle, app_get_toggle_state(app, "dashboard_toggle"))
  expect_equal(shadow_toggle,    app_get_toggle_state(app, "shadow_toggle"))
  expect_equal(shadow_sm_toggle, app_get_toggle_state(app, "shadow_sm_toggle"))
  expect_equal(shadow_lg_toggle, app_get_toggle_state(app, "shadow_lg_toggle"))
}

for (app_type in app_types) {
  expect_screenshot <- function(app, variant) {
    app$expect_screenshot(
      threshold = 15,
      name = glue("{app_type}_{variant}")
    )
  }

  describe(app_type, {
    app_variant <- NULL
    is_flow <- grepl("^flow", app_type)

    it("loads the app UI variant", {
      app_variant <<- app_for_variant(
        app,
        ui = app_type,
        width = if (is_flow)  1000 else 1200,
        height = if (is_flow) 1200 else 800
      )

      expect_false(is.null(app_variant))
    })

    skip_if(is.null(app_variant), "Failed to load app variant")
    withr::defer(app_variant$stop())

    it("light mode", {
      variant_settings(app_variant) # ensure toggles are all off
      expect_screenshot(app_variant, "01_mode_light")
    })

    add_dashboard <- !app_type %in% c("navbar", "sidebar")

    if (add_dashboard) {
      it("with bslib-page-dashboard class", {
        variant_settings(app_variant, dashboard_toggle = add_dashboard)
        expect_screenshot(app_variant, "02_class_dashboard")
      })
    }

    it("no shadows", {
      variant_settings(app_variant, shadow_toggle = TRUE, dashboard_toggle = add_dashboard)
      expect_screenshot(app_variant, "03_class_no-shadow")
    })

    it("small shadows", {
      variant_settings(app_variant, shadow_sm_toggle = TRUE, dashboard_toggle = add_dashboard)
      expect_screenshot(app_variant, "04_class_small-shadow")
    })

    it("dark mode", {
      variant_settings(app_variant, dashboard_toggle = add_dashboard)
      app_variant$run_js("document.documentElement.dataset.bsTheme='dark'")
      app_variant$wait_for_js("document.documentElement.dataset.bsTheme === 'dark'")
      Sys.sleep(1) # wait for transition
      expect_screenshot(app_variant, "05_mode_dark")
    })

    it("classic mode (default)", {
      app_classic <- app_for_variant(
        app,
        ui = app_type,
        dashboard = "false",
        width = if (is_flow)  1000 else 1200,
        height = if (is_flow) 1200 else 800
      )
      withr::defer(app_classic$stop())
      expect_screenshot(app_classic, "06_classic")
    })

    it("classic mode (with shadows)", {
      app_classic_shade <- app_for_variant(
        app,
        ui = app_type,
        dashboard = "false",
        shadows = "true",
        width = if (is_flow)  1000 else 1200,
        height = if (is_flow) 1200 else 800
      )
      withr::defer(app_classic_shade$stop())
      expect_screenshot(app_classic_shade, "07_classic_shadows")
    })
  })
}

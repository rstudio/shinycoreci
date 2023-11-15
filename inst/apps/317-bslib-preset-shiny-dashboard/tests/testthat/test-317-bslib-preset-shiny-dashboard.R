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
app <- AppDriver$new(
  name = "317-bslib-preset-shiny-dashboard",
  variant = this_platform,
  height = 800,
  width = 1200,
  seed = 2023*11*13,
  view = interactive(),
  options = list(bslib.precompiled = FALSE),
  screenshot_args = list(
    selector = "viewport",
    delay = 1,
    options = list(captureBeyondViewport = FALSE)
  )
)
withr::defer(app$stop())

shinytest2_js <- local({
  js_file <- system.file("internal", "js", "shiny-tracer.js", package = "shinytest2")
  js_content <- readLines(js_file)
  paste(js_content, collapse = "\n")
})

nav_to_variant <- function(app, ...) {
  params <- list(...)
  params <- purrr::compact(params)
  params <- purrr::imap(params, function(value, name) sprintf("%s=%s", name, value))
  params <- paste0(params, collapse = "&")

  url <- sprintf("%s?%s", app$get_url(), params)
  chrm <- app$get_chromote_session()

  p <- chrm$Page$navigate(url, wait_ = FALSE)$
    then(function(...) chrm$Page$loadEventFired(wait_ = FALSE))$
    then(function(...) chrm$Runtime$evaluate(shinytest2_js, wait_ = FALSE))$
    then(function(...) app$wait_for_idle())

  chrm$wait_for(p)
  invisible(app)
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
  screenshot_counter <- 0

  expect_screenshot <- function(variant) {
    screenshot_counter <<- screenshot_counter + 1
    count <- sprintf("%02d", screenshot_counter)

    app$expect_screenshot(
      threshold = 15,
      name = glue("{app_type}_{count}_{variant}")
    )
  }

  describe(app_type, {
    loaded <- FALSE

    it("loads the app UI variant", {
      nav_to_variant(app, ui = app_type)

      is_flow <- grepl("^flow", app_type)
      app$set_window_size(
        width = if (is_flow)  1000 else 1200,
        height = if (is_flow) 1200 else 800
      )

      loaded <<- TRUE
      expect_true(loaded)
    })

    skip_if_not(loaded)

    it("light mode", {
      variant_settings(app) # ensure toggles are all off
      expect_screenshot("mode_light")
    })

    add_dashboard <- !app_type %in% c("navbar", "sidebar")

    if (add_dashboard) {
      it("with bslib-page-dashboard class", {
        variant_settings(app, dashboard_toggle = add_dashboard)
        expect_screenshot("class_dashboard")
      })
    }

    it("no shadows", {
      variant_settings(app, shadow_toggle = TRUE, dashboard_toggle = add_dashboard)
      expect_screenshot("class_no-shadow")
    })

    it("small shadows", {
      variant_settings(app, shadow_sm_toggle = TRUE, dashboard_toggle = add_dashboard)
      expect_screenshot("class_small-shadow")
    })

    it("dark mode", {
      variant_settings(app, dashboard_toggle = add_dashboard)
      app$run_js("document.documentElement.dataset.bsTheme='dark'")
      app$wait_for_js("document.documentElement.dataset.bsTheme === 'dark'")
      Sys.sleep(1) # wait for transition
      expect_screenshot("mode_dark")
    })

    it("classic mode (default)", {
      nav_to_variant(app, ui = app_type, dashboard = "false")
      expect_screenshot("classic")
    })

    it("classic mode (with shadows)", {
      nav_to_variant(app, ui = app_type, dashboard = "false", shadows = "true")
      expect_screenshot("classic_shadows")
    })
  })
}

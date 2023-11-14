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

if (platform_variant(os_name = FALSE) != r_release) {
  skip(glue("Screenshots with R release only"))
}

this_platform <- platform_variant()
this_platform <- sub(r_release, "release", this_platform, fixed = TRUE)

# Setup App  --------------------------------------------------
app <- AppDriver$new(
  name = "317-bslib-dashboard",
  variant = this_platform,
  height = 800,
  width = 1200,
  seed = 2023*11*13,
  view = interactive(),
  options = list(bslib.precompiled = FALSE),
  screenshot_args = list(
    selector = "viewport",
    delay = 0.5,
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

for (app_type in app_types) {
  expect_screenshot <- function(variant) {
    app$expect_screenshot(
      threshold = 10,
      name = glue("{app_type}_{variant}")
    )
  }

  describe(app_type, {
    nav_to_variant(app, ui = app_type)

    is_flow <- grepl("^flow", app_type)
    app$set_window_size(
      width = if (is_flow)  1000 else 1200,
      height = if (is_flow) 1200 else 800
    )

    it("light mode", {
      expect_screenshot("mode_light")
    })

    if (!app_type %in% c("navbar", "sidebar")) {
      it("with bslib-page-dashboard class", {
        app$set_inputs(dashboard_toggle = TRUE)
        expect_screenshot("class_dashboard")
      })
    }

    it("no shadows", {
      app$set_inputs(shadow_toggle = TRUE)
      expect_screenshot("class_no-shadow")
    })

    it("small shadows", {
      app$set_inputs(shadow_sm_toggle = TRUE, shadow_toggle = FALSE)
      expect_screenshot("class_small-shadow")
    })

    it("dark mode", {
      app$set_inputs(shadow_sm_toggle = FALSE)
      app$run_js("document.documentElement.dataset.bsTheme='dark'")
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

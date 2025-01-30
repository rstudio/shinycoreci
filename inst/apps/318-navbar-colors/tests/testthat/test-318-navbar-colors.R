library(shinytest2)

release <- jsonlite::fromJSON("https://api.r-hub.io/rversions/resolve/release")
release <- paste0(
  strsplit(release$version, ".", fixed = TRUE)[[1]][1:2],
  collapse = "."
)

is_testing_on_ci <-
  identical(Sys.getenv("CI"), "true") && testthat::is_testing()
is_mac_release <- identical(paste0("mac-", release), platform_variant())

# These tests are all screenshots that only happen on macos with latest R
if (!is_mac_release) {
  test_that("tests pass; no screenshots required", expect_true(TRUE))
  skip("Only performing screenshot tests on macOS with r-release.")
}

app_new <- function(app_name, version = 5, preset = "shiny") {
  withr::local_envvar(list(TEST_VERSION = version, TEST_PRESET = preset))

  AppDriver$new(
    app_dir = rprojroot::find_package_root_file(
      "inst",
      "apps",
      "318-navbar-colors",
      app_name
    ),
    name = sprintf("318-navbar-colors_%s_%s_bs%s", preset, app_name, version),
    variant = NULL,
    height = 800,
    width = 1200,
    view = rlang::is_interactive(),
    options = list(bslib.precompiled = FALSE),
    expect_values_screenshot_args = FALSE,
    screenshot_args = list(
      selector = "viewport",
      delay = 0.5,
      options = list(captureBeyondViewport = FALSE)
    )
  )
}

app_names <- c(
  "01-default",
  "02-global",
  "03-light-dark",
  "04-navbar-options",
  "05-primary-dark"
)

for (app_name in app_names) {
  for (version in unlist(bslib::versions())) {
    if (app_name == "05-primary-dark" && version != "5") next

    presets <- c(
      bslib::builtin_themes(version),
      bslib::bootswatch_themes(version)
    )

    for (preset in presets) {
      if (app_name %in% app_names[2:4] && preset != "shiny") {
        # These apps test static navbar colors, no need to test all presets
        next
      }

      test_that(sprintf("%s - %s (bs%s)", app_name, preset, version), {
        app <- app_new(app_name, version, preset)

        app$expect_screenshot(name = "01-light", threshold = 10)

        if (version >= 5) {
          app$run_js(
            "document.getElementById('color_mode').setAttribute('mode', 'dark')"
          )
          app$expect_screenshot(name = "02-dark", threshold = 10)
        }

        app$stop()
      })
    }
  }
}

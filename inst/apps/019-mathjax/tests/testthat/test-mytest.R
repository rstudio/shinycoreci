library(shinytest2)

expect_screenshot_mac_release <- local({
  release <- jsonlite::fromJSON("https://api.r-hub.io/rversions/resolve/release")$version
  release <- paste0(
    strsplit(release, ".", fixed = TRUE)[[1]][1:2],
    collapse = "."
  )

  is_testing_on_ci <- identical(Sys.getenv("CI"), "true") && testthat::is_testing()
  is_mac_release <- identical(paste0("mac-", release), platform_variant())

  DO_SCREENSHOT <- is_testing_on_ci && is_mac_release
  function(app, ..., threshold = 2) {
    if (!DO_SCREENSHOT) return(invisible(app))
    shinycoreci::expect_stable_screenshot(app, ..., threshold = threshold)
  }
})

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(
    variant = shinytest2::platform_variant(),
    load_timeout = 15000,
    seed = 100,
    shiny_args = list(display.mode = "normal")
  )

  app$expect_values()
  expect_screenshot_mac_release(app)

  app$set_inputs(ex5_visible = TRUE)
  app$expect_values()
  expect_screenshot_mac_release(app)
})

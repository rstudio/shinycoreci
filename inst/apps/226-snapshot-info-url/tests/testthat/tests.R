test_that("text passes", {
  app <- AppDriver$new(seed = 100, variant = shinytest2::platform_variant(), shiny_args = list(display.mode = "normal"))

  app$wait_for_js("$('#status').text().length > 0")

  testthat::expect_equal(
    app$get_js("$('#status').text()"),
    "PASS"
  )
})

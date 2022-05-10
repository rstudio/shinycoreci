library(shinytest2)

test_that("Make sure script tags are executed", {
  app <- AppDriver$new()

  app$wait_for_js("window.insert_ui_script")

  expect_equal(
    app$get_js("window.insert_ui_script"),
    TRUE
  )
})

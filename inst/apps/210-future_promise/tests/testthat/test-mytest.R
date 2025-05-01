skip_if_not_installed("future", "1.21.0")

library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant())

  on.exit({
    print(sessioninfo::session_info())
    print(app$get_logs())
  })

  # Verify promise counts are higher than future counts
  expect_counts <- function() {
    future_counts = as.numeric(app$get_value(output = "future_counts"))
    promise_counts = as.numeric(app$get_value(output = "promise_counts"))

    expect_gt(promise_counts, future_counts)
  }

  wait_for_idle <- function() {
    app$wait_for_idle(duration = 3 * 1000, timeout = 24 * 60 * 60 * 1000) # wait a day (Inf)
  }

  app$click("go_future_future")
  wait_for_idle()

  app$click("go_future_promise")
  wait_for_idle()

  expect_counts()

  # again
  app$click("go_future_future")
  wait_for_idle()

  app$click("go_future_promise")
  wait_for_idle()

  expect_counts()
})

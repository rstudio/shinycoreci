library(shinytest2)


test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(
    seed = 100,
    wait = FALSE
  )

  wait_for_number <- function(i) {
    app$wait_for_js(paste0("parseInt($('#out').text(), 10) == ", i, ";"))
    if (i > 0) {
      app$wait_for_js(paste0("parseInt($('#out_flushed').text(), 10) == ", i - 1, ";"))
    }
    expect_true(TRUE)
  }

  expect_true(TRUE)

  wait_for_number(1)
  wait_for_number(2)
  wait_for_number(3)
  wait_for_number(4)
  wait_for_number(5)
  wait_for_number(6)
  wait_for_number(7)
  wait_for_number(8)
  wait_for_number(9)
  wait_for_number(10)

  app$wait_for_idle(duration = 2.5 * 1000, timeout = 10 * 1000)
  expect_equal(trimws(app$get_text("#status")), "Pass!")
})

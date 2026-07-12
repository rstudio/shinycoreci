test_that("expect_stable_screenshot waits for browser readiness before capture", {
  calls <- character()
  app <- new.env(parent = emptyenv())
  app$wait_for_idle <- function(...) calls <<- c(calls, "idle")
  app$wait_for_js <- function(script, ...) {
    calls <<- c(calls, paste("js", script))
  }
  app$run_js <- function(script, ...) calls <<- c(calls, "paint")
  app$expect_screenshot <- function(...) calls <<- c(calls, "screenshot")

  expect_stable_screenshot(app)

  expect_equal(calls[c(1, 3, 4, 5)], c("idle", "paint", "js window.shinycoreciPaintReady", "screenshot"))
  expect_match(calls[[2]], "document.fonts.status === 'loaded'", fixed = TRUE)
  expect_match(calls[[2]], "recalculating", fixed = TRUE)
  expect_match(calls[[2]], "link[rel=stylesheet]", fixed = TRUE)
  expect_match(calls[[2]], "document.images", fixed = TRUE)
})

test_that("expect_stable_screenshot includes an app-specific readiness condition", {
  scripts <- character()
  app <- new.env(parent = emptyenv())
  app$wait_for_idle <- function(...) NULL
  app$wait_for_js <- function(script, ...) scripts <<- c(scripts, script)
  app$run_js <- function(...) NULL
  app$expect_screenshot <- function(...) NULL

  expect_stable_screenshot(app, ready = "window.widgetReady")

  expect_match(scripts[[1]], "window.widgetReady", fixed = TRUE)
})

test_that("expect_stable_screenshot forwards screenshot arguments", {
  received <- NULL
  app <- new.env(parent = emptyenv())
  app$wait_for_idle <- function(...) NULL
  app$wait_for_js <- function(...) NULL
  app$run_js <- function(...) NULL
  app$expect_screenshot <- function(...) received <<- list(...)

  expect_stable_screenshot(app, name = "ready", threshold = 7)

  expect_equal(received$name, "ready")
  expect_equal(received$threshold, 7)
})

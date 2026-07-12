#' Capture a screenshot after the browser has finished rendering
#'
#' Waits for Shiny, fonts, layout, and browser painting before delegating to
#' [shinytest2::AppDriver]`$expect_screenshot()`.
#'
#' @param app A `shinytest2::AppDriver` instance.
#' @param ... Arguments passed to `app$expect_screenshot()`.
#' @param ready An optional JavaScript expression for app-specific readiness.
#' @param timeout Maximum time to wait, in milliseconds.
#'
#' @export
expect_stable_screenshot <- function(
  app,
  ...,
  ready = NULL,
  timeout = 15 * 1000
) {
  app$wait_for_idle(timeout = timeout)

  conditions <- c(
    "!document.querySelector('.recalculating, .shiny-busy')",
    "(document.fonts === undefined || document.fonts.status === 'loaded')",
    "Array.from(document.querySelectorAll('link[rel=stylesheet]')).every((x) => x.sheet !== null)",
    "Array.from(document.images).every((x) => x.complete)",
    ready
  )
  app$wait_for_js(paste(conditions, collapse = " && "), timeout = timeout)

  app$run_js(paste0(
    "window.shinycoreciPaintReady = false;",
    "requestAnimationFrame(() => requestAnimationFrame(() => {",
    "window.shinycoreciPaintReady = true;",
    "}));"
  ))
  app$wait_for_js("window.shinycoreciPaintReady", timeout = 3 * 1000)

  app$expect_screenshot(...)
}

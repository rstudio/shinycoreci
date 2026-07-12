# Capture a screenshot after the browser has finished rendering

Waits for Shiny, fonts, layout, and browser painting before delegating
to
[shinytest2::AppDriver](https://rstudio.github.io/shinytest2/reference/AppDriver.html)`$expect_screenshot()`.

## Usage

``` r
expect_stable_screenshot(app, ..., ready = NULL, timeout = 15 * 1000)
```

## Arguments

- app:

  A
  [`shinytest2::AppDriver`](https://rstudio.github.io/shinytest2/reference/AppDriver.html)
  instance.

- ...:

  Arguments passed to `app$expect_screenshot()`.

- ready:

  An optional JavaScript expression for app-specific readiness.

- timeout:

  Maximum time to wait, in milliseconds.

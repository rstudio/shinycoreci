library(shinytest2)
library(testthat)

test_that("MathJax block contains a mpg equation", {
  app <- AppDriver$new(variant = shinytest2::platform_variant())

  app$wait_for_js("$('#MathJax-Span-1').length > 0", timeout = 10 * 1000)
  math_text <- app$get_text("#MathJax-Span-1")

  expect_equal(math_text, "𝑚𝑝𝑔=37.8846+−2.8758𝑐𝑦𝑙")
})

library(shinytest2)
library(testthat)

test_that("MathML block contains α2", {
  app <- AppDriver$new(variant = shinytest2::platform_variant())

  app$wait_for_js("$('#ex1 .MJX_Assistive_MathML.MJX_Assistive_MathML_Block').length > 0")
  math_text <- app$get_text("#ex1 .MJX_Assistive_MathML.MJX_Assistive_MathML_Block")

  expect_equal(math_text, "α2")
})

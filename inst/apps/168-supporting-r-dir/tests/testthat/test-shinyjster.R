withr:::with_options(list(shiny.autoload.r = TRUE), {
  shinyjster::testthat_shinyjster()
})

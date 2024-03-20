library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(
    load_timeout = 15000, seed = 100, 
    shiny_args = list(display.mode = "normal"),
    # Use legacy datatable implementation just for the 
    # info$datatable$colnames test below. We could, of course, 
    # update that test, but it's also good to test the legacy.
    options = list(shiny.legacy.datatable = TRUE)
  )

  # Wait until an async value is available
  app$wait_for_value(output = "printa", timeout = 10 * 1000)

  info <- app$get_values(output = TRUE)$output

  expect_img <- function(img) {
    expect_gt(nchar(img$src), 500)
  }

  expect_img(info$plot)
  expect_img(info$plota)
  expect_equal(info$plot$alt, "Plot object")
  expect_equal(info$plota$alt, "Plot object")

  expect_equal(info$text, "hello")
  expect_equal(info$texta, "hello")

  expect_equal(info$print, "[1] \"hello\"")
  expect_equal(info$printa, "[1] \"hello\"")

  expect_equal(info$print2, "[1] \"hello\"")
  expect_equal(info$print2a, "[1] \"hello\"")

  expect_equal(info$datatable$colnames, c("speed", "dist"))
  expect_equal(info$datatablea$colnames, c("speed", "dist"))

  expect_img(info$image)
  expect_img(info$imagea)

  expect_match(info$table, "4.00", fixed = TRUE)
  expect_match(info$table, "22.00", fixed = TRUE)
  expect_match(info$tablea, "4.00", fixed = TRUE)
  expect_match(info$tablea, "22.00", fixed = TRUE)

  expect_equal(info$ui$html, htmltools::HTML("<h1>hello world</h1>"))
  expect_equal(info$uia$html, htmltools::HTML("<h1>hello world</h1>"))
})

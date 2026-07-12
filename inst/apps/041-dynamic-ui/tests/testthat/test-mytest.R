library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  set_input_and_wait <- function(...) {
    app$set_inputs(...)
    app$wait_for_idle()
  }
  expect_screenshot_and_values <- function() {
    app$expect_values()
    shinycoreci::expect_stable_screenshot(app)
  }

  expect_dynamic_value <- function(input_type, value) {
    set_input_and_wait(input_type = input_type)
    set_input_and_wait(dynamic = value)
    expect_screenshot_and_values()
  }

  expect_dynamic_value("slider", 14)

  expect_dynamic_value("text", "abcd")

  expect_dynamic_value("numeric", 100)
  expect_dynamic_value("checkbox", FALSE)

  expect_dynamic_value("checkboxGroup", c("option1", "option2"))

  set_input_and_wait(dynamic = "option1")
  set_input_and_wait(dynamic = character(0))
  expect_screenshot_and_values()

  expect_dynamic_value("radioButtons", "option1")

  expect_dynamic_value("selectInput", "option1")

  set_input_and_wait(input_type = "selectInput (multi)")
  expect_screenshot_and_values()

  set_input_and_wait(dynamic = "option1")
  set_input_and_wait(dynamic = character(0))
  expect_screenshot_and_values()

  expect_dynamic_value("date", "2020-01-31")

  expect_dynamic_value("daterange", c("2020-01-08", "2020-01-31"))
})

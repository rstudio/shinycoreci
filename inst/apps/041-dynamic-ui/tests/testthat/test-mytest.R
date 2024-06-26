library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$set_inputs(dynamic = 14)
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(input_type = "text")
  app$set_inputs(dynamic = "abcd")
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(input_type = "numeric")
  app$set_inputs(dynamic = 100)
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(input_type = "checkbox")
  app$wait_for_idle() # linux 3.6 has some issues; add some delay
  app$set_inputs(dynamic = FALSE)
  app$wait_for_idle() # linux 3.6 has some issues; add some delay
  app$expect_values() # Should be `dynamic = FALSE`
  app$expect_screenshot()

  app$set_inputs(input_type = "checkboxGroup")
  app$set_inputs(dynamic = c("option1", "option2"))
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(dynamic = "option1")
  app$set_inputs(dynamic = character(0))
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(input_type = "radioButtons")
  app$set_inputs(dynamic = "option1")
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(input_type = "selectInput")
  app$set_inputs(dynamic = "option1")
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(input_type = "selectInput (multi)")
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(dynamic = "option1")
  app$set_inputs(dynamic = character(0))
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(input_type = "date")
  app$wait_for_idle() # linux 4.0 has some issues; add some delay
  app$set_inputs(dynamic = "2020-01-31")
  app$wait_for_idle() # linux 4.0 has some issues; add some delay
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(input_type = "daterange")
  app$set_inputs(dynamic = c("2020-01-08", "2020-01-31"))
  app$expect_values()
  app$expect_screenshot()
})

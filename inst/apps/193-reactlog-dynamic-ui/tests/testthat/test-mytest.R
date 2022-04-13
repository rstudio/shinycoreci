library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))


  app$set_inputs(`reactlog_module-refresh` = "click")
  Sys.sleep(4)
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(dynamic = 14)
  app$set_inputs(`reactlog_module-refresh` = "click")
  Sys.sleep(4)
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(input_type = "text")
  app$set_inputs(dynamic = "abcd")

  app$set_inputs(input_type = "numeric")
  app$set_inputs(dynamic = 100)

  app$set_inputs(input_type = "checkbox")
  app$set_inputs(dynamic = FALSE)

  app$set_inputs(input_type = "checkboxGroup")
  app$set_inputs(dynamic = c("option1", "option2"))

  app$set_inputs(dynamic = "option1")
  app$set_inputs(dynamic = character(0))

  app$set_inputs(input_type = "radioButtons")
  app$set_inputs(dynamic = "option1")

  app$set_inputs(input_type = "selectInput")
  app$set_inputs(dynamic = "option1")

  app$set_inputs(input_type = "selectInput (multi)")

  app$set_inputs(dynamic = "option1")
  app$set_inputs(dynamic = character(0))

  app$set_inputs(input_type = "date")
  app$set_inputs(dynamic = "2020-01-31")

  app$set_inputs(input_type = "daterange")
  app$set_inputs(dynamic = c("2020-01-08", "2020-01-31"))

  app$set_inputs(`reactlog_module-refresh` = "click")
  Sys.sleep(4)
  app$expect_values()
  app$expect_screenshot()
})

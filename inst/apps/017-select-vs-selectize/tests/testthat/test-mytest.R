library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$expect_values()
  app$expect_screenshot()
  app$set_inputs(in1 = "Alaska")
  app$set_inputs(in1 = "California")
  app$set_inputs(in2 = "Arkansas")
  app$set_inputs(in3 = "Alabama")
  app$set_inputs(in3 = "Alaska")
  app$set_inputs(in3 = "Arizona")
  app$set_inputs(in3 = "Alabama")
  app$set_inputs(in3 = "Arkansas")
  app$set_inputs(in6 = "Arizona")
  app$set_inputs(in6 = c("Arizona", "California"))
  app$set_inputs(in6 = c("Arizona", "California", "Connecticut"))
  app$set_inputs(in5 = "Arkansas")
  app$set_inputs(in4 = "Arkansas")
  app$expect_values()
  app$expect_screenshot()
})

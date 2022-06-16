library(shinytest2)

test_that("{shinytest2} recording: mytest", {
  app <- AppDriver$new(variant = platform_variant(),
    seed = 100, height = 1123, width = 1167, shiny_args = list(display.mode = "normal"))
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(decimal = 0.9)
  app$set_inputs(date = "2010-05-01")
  app$set_inputs(date2 = c("2010-03-01", "2010-04-29"))

  # Should be equivalent to "2010-03-01", with some adjustment for time zone.
  app$set_inputs(datetime = 1.272708e+12)

  # Should be equivalent to "2010-03-01", "2010-04-29", with some adjustment for
  # time zone.
  app$set_inputs(datetime2 = c(1267437600000, 1272535200000))
  app$expect_values()
  app$expect_screenshot()
})

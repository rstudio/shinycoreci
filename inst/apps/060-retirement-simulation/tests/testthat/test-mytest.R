library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, width = 1000, shiny_args = list(display.mode = "normal"))

  a_dist <- app$wait_for_value(output = "a_distPlot")
  b_dist <- app$wait_for_value(output = "b_distPlot")
  app$expect_values()
  app$expect_screenshot()


  app$set_inputs(a_recalc = "click")
  app$set_inputs(a_monthly_withdrawals = 68000)
  app$set_inputs(b_recalc = "click")
  app$set_inputs(b_recalc = "click")
  app$set_inputs(b_annual_ret_std_dev = 12.3)
  app$set_inputs(b_annual_ret_std_dev = 16.8)
  app$set_inputs(b_n_sim = 1070)

  app$wait_for_value(output = "a_distPlot", ignore = list(NULL,
    a_dist))
  app$wait_for_value(output = "b_distPlot", ignore = list(NULL,
    b_dist))
  app$expect_values()
  app$expect_screenshot()
})

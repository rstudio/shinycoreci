library(shinytest2)
skip_on_platform(c("windows", "linux"),
  reason = "Only testing snaps on macOS"
)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(
    variant = shinytest2::platform_variant(),
    seed = 100,
    shiny_args = list(display.mode = "normal"),
    options = list("shiny.json.digits" = 4)
  )

  Sys.sleep(2) # wait for widget
  app$expect_values()
  app$expect_screenshot()

  app$set_inputs(year = c(1994, 2005))
  app$set_inputs(year = c(1997, 2005))
  app$set_inputs(plot_type = "column")
  app$set_inputs(theme = "fivethirtyeight")
  Sys.sleep(2) # wait for widget / css
  app$expect_values()
  app$expect_screenshot()
})

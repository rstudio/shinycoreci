library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 100, shiny_args = list(display.mode = "normal"))

  app$expect_values()
  app$expect_screenshot()

  # Add Dynamic-1
  app$set_inputs(add = "click")
  app$set_inputs(tabs = "Dynamic-1")
  app$expect_values()
  app$expect_screenshot()

  # Remove Foo tabs
  app$set_inputs(removeFoo = "click")
  app$expect_values()
  app$expect_screenshot()

  # Add Foo-1 (also opens tab)
  app$set_inputs(addFoo = "click")
  app$expect_values()
  app$expect_screenshot()

  # View Default Hello tab
  app$set_inputs(tabs = "Hello")
  app$expect_values()
  app$expect_screenshot()

  # Add Dynamic-2 tab and show it in menu. Do not show Dynamic-2 tab.
  app$set_inputs(add = "click")
  app$click(selector = ".dropdown-toggle")
  app$expect_values()
  app$expect_screenshot()
  app$click(selector = ".dropdown-toggle")

  # Add Foo-2 tab (also opens tab)
  app$set_inputs(addFoo = "click")
  app$expect_values()
  app$expect_screenshot()

  # Remove second Foo tab
  app$set_inputs(removeFoo = "click")
  app$expect_values()
  app$expect_screenshot()
})

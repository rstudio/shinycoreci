library(shinytest2)

test_that("{shinytest2} recording: 308-sidebar-kitchen-sink", {
  height <- 1200
  width <- 1600

  app <- AppDriver$new(
    variant = platform_variant(),
    name = "308-sidebar-kitchen-sink",
    view = interactive(),
    height = height,
    width = width
  )

  app$expect_screenshot()

  app$set_inputs(navbar = "Fill+Scroll")
  app$expect_screenshot()

  # Contents should render to their natural height on mobile
  app$set_window_size(width = 500, height = 1000)
  app$expect_screenshot()
  app$set_window_size(width = width, height = height)

  app$set_inputs(navbar = "Scroll")
  app$expect_screenshot()

  app$set_inputs(navbar = "Global card sidebar")
  app$set_inputs(card_tab_sidebar = "Tab 2")
  Sys.sleep(1) # Wait for the tab to receive focus
  app$expect_screenshot()

  app$click("toggle_sidebar")
  Sys.sleep(1) # Wait for transition to complete
  app$expect_screenshot()
})

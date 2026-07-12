library(shinytest2)

# Only take screenshots on mac + r-release to reduce diff noise
release <- jsonlite::fromJSON("https://api.r-hub.io/rversions/resolve/release")$version
release <- paste0(
  strsplit(release, ".", fixed = TRUE)[[1]][1:2],
  collapse = "."
)

is_testing_on_ci <- identical(Sys.getenv("CI"), "true") && testthat::is_testing()
is_mac_release <- identical(paste0("mac-", release), platform_variant())

DO_SCREENSHOT <- (is_testing_on_ci && is_mac_release) ||
  identical(Sys.getenv("SHINYTEST2_SCREENSHOT"), "true")

test_that("{shinytest2} recording: 308-sidebar-kitchen-sink", {
  height <- 1200
  width <- 1600

  app <- AppDriver$new(
    variant = platform_variant(),
    name = "308-sidebar-kitchen-sink",
    view = interactive(),
    seed = 101,
    height = height,
    width = width,
    # TODO: rstudio/shinytest2#367
    screenshot_args = list(
      selector = "viewport",
      delay = 1.5,
      options = list(captureBeyondViewport = FALSE)
    )
  )

  expect_screenshot <- function() {
    if (DO_SCREENSHOT) app$expect_screenshot()
  }

  expect_screenshot()

  app$set_inputs(navbar = "Fill+Scroll")
  expect_screenshot()

  # Contents should render to their natural height on mobile
  app$set_window_size(width = 500, height = 2000)
  expect_screenshot()
  app$set_window_size(width = width, height = height)

  app$set_inputs(navbar = "Scroll")
  expect_screenshot()

  app$set_inputs(navbar = "Global card sidebar")
  app$set_inputs(card_tab_sidebar = "Tab 2")
  Sys.sleep(1) # Wait for the tab to receive focus
  expect_screenshot()

  app$click("toggle_sidebar")
  app$wait_for_js("
    document.querySelector('.bslib-sidebar-layout.transitioning') === null
  ")
  expect_screenshot()
})

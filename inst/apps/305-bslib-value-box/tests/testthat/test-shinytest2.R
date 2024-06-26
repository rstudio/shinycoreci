library(shinytest2)

# Only run these tests on mac + r-release
# (To reduce the amount of screenshot diffing noise)
release <- rversions::r_release()$version
release <- paste0(
  strsplit(release, ".", fixed = TRUE)[[1]][1:2],
  collapse = "."
)
if (!identical(paste0("mac-", release), platform_variant())) {
  skip("Not mac + r-release")
}
if (length(dir("_snaps")) > 1) {
  stop("More than 1 _snaps folder found!")
}


test_that("{shinytest2} recording: value_box", {

  width <- 1720
  height <- 1100

  app <- AppDriver$new(
    variant = platform_variant(), name = "value_box",
    width = width, height = height,
    view = interactive(),
    options = list(bslib.precompiled = FALSE)
  )
  expect_screenshot <- function(..., wait = 1, viewport = TRUE, threshold = 3) {
    Sys.sleep(wait)
    args <- rlang::list2(..., threshold = threshold)
    if (viewport) {
      rect <- c(x = 0, y = 0, width = width, height = height)
      new_args <- list(screenshot_args = list(cliprect = rect))
      args <- modifyList(new_args, args)
    }
    rlang::inject(app$expect_screenshot(!!!args))
  }

  expect_screenshot()

  app$run_js('$($(".bslib-full-screen-enter")[0]).click()')
  expect_screenshot()

  app$run_js('$(".bslib-full-screen-exit").click()')
  app$run_js('$($(".bslib-full-screen-enter")[1]).click()')
  expect_screenshot()

  app$run_js('$(".bslib-full-screen-exit").click()')
  app$set_window_size(width = 500, height = 1600)
  expect_screenshot(wait = 3, viewport = FALSE)
})

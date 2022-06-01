library(shinytest2)


test_that("Migrated shinytest test: mytest.R", {
  # old_args <- chromote::default_chrome_args()
  # withr::defer({
  #   chromote::set_chrome_args(old_args)
  # })
  # # https://github.com/puppeteer/puppeteer/issues/2410#issuecomment-560573612
  # chromote::set_chrome_args(c("--font-render-hinting=none", "--disable-font-subpixel-positioning", old_args))

  app <- AppDriver$new(variant = shinytest2::platform_variant(),
    seed = 54322)

  refresh_and_expect <- function() {
    app$set_inputs(`reactlog_module-refresh` = "click")
    Sys.sleep(1.5) # wait for reactlog to settle
    app$expect_values()
    app$expect_screenshot()
  }

  refresh_and_expect()

  app$set_inputs(obs = 9)
  app$set_inputs(obs = 8)

  refresh_and_expect()
})

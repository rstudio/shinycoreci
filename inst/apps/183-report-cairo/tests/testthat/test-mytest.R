library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  skip_if_not_installed("ragg", "0.2")
  skip_if_not_installed("systemfonts", "0.3") # systemfonts::register_font


  tryCatch(require("Cairo"), error = function(e) {
    ## Error typically seen on macos-latest w/ R 3.6.3:
    # error: unable to load shared object '/Users/runner/work/_temp/Library/Cairo/libs/Cairo.so':
    # dlopen(/Users/runner/work/_temp/Library/Cairo/libs/Cairo.so, 6): Library not loaded: /opt/X11/lib/libcairo.2.dylib
    # Referenced from: /Users/runner/work/_temp/Library/Cairo/libs/Cairo.so
    # Reason: Incompatible library version: Cairo.so requires version 11403.0.0 or later, but libcairo.2.dylib provides version 1.0.0
    message("Error loading {Cairo} package: ", e)
    skip("Cairo package could not be loaded")
  })

  app <- AppDriver$new(variant = shinytest2::platform_variant())

  app$expect_values()
  app$expect_screenshot()

})

library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant())

  expect_tab <- function(name) {
    app$run_js(script = paste0("$(\".nav [data-value=", name, "]\").tab(\"show\")"))
    # Wait for at least one tab to be shown
    app$wait_for_js(paste0('
      $(".tab-pane[data-value=', name, ']").
        map(function(){ return $(this).is(":visible") }).
        toArray().
        some((x) => x)
    '))
    app$expect_values()
    app$expect_screenshot()
  }

  expect_tab("b")
  expect_tab("c")
})

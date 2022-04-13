library(shinytest2)

test_that("Migrated shinytest test: mytest.R", {
  app <- AppDriver$new(variant = shinytest2::platform_variant(), wait = FALSE)

  app$expect_values()
  app$expect_screenshot()
  # This is the literal data structure that is sent for output$status. We're
  # waiting for it to change so that it no longer says "Waiting...". The data
  # structure was retrieved by using `dput(app$getAllValues()$output$status)`.
  app$wait_for_value(output = "status", ignore = list(NULL, list(html = structure("<h4>\n  <span style=\"background-color: #dddddd;\">Waiting...</span>\n</h4>",
    html = TRUE, class = c("html", "character")), deps = list())),
    timeout = 20000)
  app$expect_values()
  app$expect_screenshot()
})

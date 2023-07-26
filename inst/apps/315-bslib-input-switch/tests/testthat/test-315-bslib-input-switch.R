library(shinytest2)

app <- AppDriver$new(
  name = "315-bslib-input-switch",
  variant = platform_variant(),
  height = 1600,
  width = 1200,
  view = interactive(),
  options = list(bslib.precompiled = FALSE),
  expect_values_screenshot_args = FALSE
)

withr::defer(app$stop())

set_input_if_not <- function(input, value) {
  current <- app$get_value(input = input)
  if (is.null(current) || !identical(current, value)) {
    app$set_inputs(!!input := value)
  }
  expect_equal(app$get_value(input = input), value)
  invisible(app)
}

test_that("initial values", {
  expect_equal(
    app$get_values(
      input = c(
        "auto_capitalization",
        "auto_correction",
        "check_spelling",
        "smart_punctuation"
      )
    )$input,
    list(
      auto_capitalization = TRUE,
      auto_correction = FALSE,
      check_spelling = TRUE,
      smart_punctuation = FALSE
    )
  )
})

test_that("toggle_switch()", {
  set_input_if_not("check_spelling", TRUE)

  app$click("toggle_spelling")
  expect_false(app$get_value(input = "check_spelling"))

  app$click("toggle_spelling")
  expect_true(app$get_value(input = "check_spelling"))
})

test_that("toggle_switch(value = )", {
  app$run_js("Shiny.setInputValue('value_update_type', 'toggle')")

  set_input_if_not("auto_correction", FALSE)
  app$click("enable_auto_correct")
  expect_true(app$get_value(input = "auto_correction"))

  set_input_if_not("auto_capitalization", TRUE)
  app$click("disable_capitalization")
  expect_false(app$get_value(input = "auto_capitalization"))
})

test_that("update_switch(value = )", {
  app$run_js("Shiny.setInputValue('value_update_type', 'update')")

  set_input_if_not("auto_correction", FALSE)
  app$click("enable_auto_correct")
  expect_true(app$get_value(input = "auto_correction"))

  set_input_if_not("auto_capitalization", TRUE)
  app$click("disable_capitalization")
  expect_false(app$get_value(input = "auto_capitalization"))
})

test_that("update_switch(label = )", {
  app$set_inputs(smart_punct_label = "Awesome Punctuation")
  label <- app$get_text('label[for="smart_punctuation"]')
  expect_equal(trimws(label), "Awesome Punctuation")
})

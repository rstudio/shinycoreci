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
  set_input_if_not("auto_correction", FALSE)
  app$click("toggle_enable_auto_correct")
  expect_true(app$get_value(input = "auto_correction"))

  set_input_if_not("auto_capitalization", TRUE)
  app$click("toggle_disable_capitalization")
  expect_false(app$get_value(input = "auto_capitalization"))
})

test_that("update_switch(value = )", {
  spelling_current <- app$get_value(input = "check_spelling")
  app$click("update_toggle_spelling")
  expect_equal(app$get_value(input = "check_spelling"), !spelling_current)

  set_input_if_not("auto_correction", FALSE)
  app$click("update_enable_auto_correct")
  expect_true(app$get_value(input = "auto_correction"))

  set_input_if_not("auto_capitalization", TRUE)
  app$click("update_disable_capitalization")
  expect_false(app$get_value(input = "auto_capitalization"))
})

test_that("update_switch(label = )", {
  app$
    set_inputs(smart_punct_label = "Awesome Punctuation")$
    wait_for_js(
      "document
        .querySelector('label[for=\"smart_punctuation\"]')
        .innerText
        .includes('Awesome')"
    )

    expect_equal(
      app$get_js('document.querySelector("label[for=\\"smart_punctuation\\"]").innerText'),
      "Awesome Punctuation"
    )
})

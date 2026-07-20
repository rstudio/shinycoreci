library(shinytest2)
if (FALSE) library(shinycoreci) # for renv

source(system.file("helpers", "keyboard.R", package = "shinycoreci"))

expect_js <- function(app, js, label = NULL) {
  expect_true(
    app$wait_for_js(!!js)$get_js(!!js),
    label = label
  )
  invisible(app)
}

app_focus_element <- function(app, selector) {
  js <- sprintf(
    "const el = document.querySelector('%s'); el.focus(); el.matches(':focus');",
    selector
  )
  expect_js(app, js, label = paste("focus on:", selector))
}

app_get_value <- function(app, selector) {
  app$get_js(sprintf("document.querySelector('%s').value", selector))
}

# Setup App  --------------------------------------------------
app <- AppDriver$new(
  name = "320-text-input-update-on-blur",
  variant = platform_variant(),
  height = 800,
  width = 1200,
  seed = 20230724,
  view = interactive(),
  options = list(bslib.precompiled = FALSE),
  expect_values_screenshot_args = FALSE,
  screenshot_args = list(selector = "viewport", delay = 0.5)
)
withr::defer(app$stop())

key_press <- key_press_factory(app)

key_press_write <- function(text) {
  for (letter in strsplit(text, character())[[1]]) {
    key_press(letter)
  }
}

test_that("textInput() -- updateOn='change'", {
  VALUE <- "Hello"
  app$set_inputs("change-txt" = VALUE, wait_ = FALSE)
  expect_equal(app$get_value(input = "change-txt"), VALUE)

  app_focus_element(app, "#change-txt")
  key_press("End")
  key_press_write(", world")

  # input has updated, even though it still has focus
  Sys.sleep(0.5)
  VALUE <- "Hello, world"
  expect_equal(app$get_value(input = "change-txt"), VALUE)
  expect_js(app, "$('#change-txt').is(':focus')")

  app$click("change-update_text")
  VALUE <- "serendipity ephemeral"
  expect_equal(app$get_value(input = "change-txt"), VALUE)
})

test_that("textInput() -- updateOn='blur'", {
  VALUE <- "Hello"
  app$set_inputs("blur-txt" = VALUE, wait_ = FALSE)
  expect_equal(app$get_value(input = "blur-txt"), VALUE)

  app_focus_element(app, "#blur-txt")
  key_press("End")
  key_press_write(", world")

  # input has not updated yet
  expect_equal(app$get_value(input = "blur-txt"), VALUE)

  # input updates after blur
  app$get_js("$('#blur-txt').blur()")
  VALUE <- "Hello, world"
  expect_equal(app$get_value(input = "blur-txt"), VALUE)

  # input updates on Enter
  app_focus_element(app, "#blur-txt")
  key_press("End")
  key_press_write("!")

  expect_equal(app$get_value(input = "blur-txt"), VALUE)
  key_press("Enter")
  VALUE <- "Hello, world!"
  expect_equal(app$get_value(input = "blur-txt"), VALUE)

  app$click('blur-update_text')
  expect_equal(
    app$get_js("document.querySelector('#blur-txt').value"),
    "serendipity ephemeral"
  )
  expect_equal(app$get_value(input = "blur-txt"), VALUE)
  app$click('blur-update_text')
  expect_equal(
    app$get_js("document.querySelector('#blur-txt').value"),
    "ephemeral mellifluous"
  )
  expect_equal(app$get_value(input = "blur-txt"), VALUE)

  key_press("Enter")
  VALUE <- "ephemeral mellifluous"
  expect_equal(app$get_value(input = "blur-txt"), VALUE)
})

test_that("textAreaInput() -- updateOn='change'", {
  VALUE <- "Hello"
  app$set_inputs("change-txtarea" = VALUE, wait_ = FALSE)
  expect_equal(app$get_value(input = "change-txtarea"), VALUE)

  app_focus_element(app, "#change-txtarea")
  key_press("End")
  key_press_write(", world")

  # input has updated, even though it still has focus
  Sys.sleep(0.5)
  VALUE <- "Hello, world"
  expect_equal(app$get_value(input = "change-txtarea"), VALUE)
  expect_js(app, "$('#change-txtarea').is(':focus')")

  app$click("change-update_text_area")
  VALUE <- "The old oak tree whispered secrets to the wind.\nClouds painted shadows on the mountain peaks."
  expect_equal(
    app$get_value(input = "change-txtarea"),
    VALUE
  )
})

test_that("textAreaInput() -- updateOn='blur'", {
  VALUE <- "Hello"
  app$set_inputs("blur-txtarea" = VALUE, wait_ = FALSE)
  expect_equal(app$get_value(input = "blur-txtarea"), VALUE)

  app_focus_element(app, "#blur-txtarea")
  key_press("End")
  key_press_write(", world")

  # input has not updated yet
  expect_equal(app$get_value(input = "blur-txtarea"), VALUE)

  # input updates after blur
  app$get_js("$('#blur-txtarea').blur()")
  VALUE <- "Hello, world"
  expect_equal(app$get_value(input = "blur-txtarea"), VALUE)

  # input does not update on Enter
  app_focus_element(app, "#blur-txtarea")
  key_press("End")
  key_press_write("!")

  expect_equal(app$get_value(input = "blur-txtarea"), VALUE)
  key_press("Enter")
  expect_equal(app$get_value(input = "blur-txtarea"), VALUE)

  # input updates on Command/Control + Enter
  key_press("Enter", command = TRUE, control = TRUE)
  VALUE <- "Hello, world!"
  expect_equal(app$get_value(input = "blur-txtarea"), VALUE)

  app$click('blur-update_text_area')
  expect_equal(
    app$get_js("document.querySelector('#blur-txtarea').value"),
    "The old oak tree whispered secrets to the wind.\nClouds painted shadows on the mountain peaks."
  )
  expect_equal(app$get_value(input = "blur-txtarea"), VALUE)
  app$click('blur-update_text_area')
  expect_equal(
    app$get_js("document.querySelector('#blur-txtarea').value"),
    "Clouds painted shadows on the mountain peaks.\nStars danced across the midnight canvas."
  )
  expect_equal(app$get_value(input = "blur-txtarea"), VALUE)

  key_press("Enter", command = TRUE, control = TRUE)
  VALUE <- "Clouds painted shadows on the mountain peaks.\nStars danced across the midnight canvas."
  expect_equal(
    app$get_value(input = "blur-txtarea"),
    VALUE
  )
})

# ---- numericInput() ----------------------------------------------------------

test_that("numericInput() -- updateOn='change'", {
  VALUE <- 10
  app$set_inputs("change-num" = VALUE, wait_ = FALSE)
  expect_equal(app$get_value(input = "change-num"), VALUE)

  app_focus_element(app, "#change-num")
  key_press("ArrowUp")

  # input has updated immediately
  VALUE <- 11
  expect_equal(app$get_value(input = "change-num"), VALUE)

  key_press("ArrowDown")
  key_press("ArrowDown")

  # input has updated immediately
  VALUE <- 9
  expect_equal(app$get_value(input = "change-num"), VALUE)

  app$click("change-update_number")
  VALUE <- 42
  expect_equal(app$get_value(input = "change-num"), VALUE)
})

test_that("numericInput() -- updateOn='blur'", {
  VALUE <- 10
  app$set_inputs("blur-num" = VALUE, wait_ = FALSE)
  expect_equal(app$get_value(input = "blur-num"), VALUE)

  app_focus_element(app, "#blur-num")
  key_press("ArrowUp")

  # input has not updated yet
  expect_equal(app$get_value(input = "blur-num"), VALUE)

  # input updates after blur
  app$get_js("$('#blur-num').blur()")
  VALUE <- 11
  expect_equal(app$get_value(input = "blur-num"), VALUE)

  # input updates on Enter
  app_focus_element(app, "#blur-num")
  key_press("ArrowDown")
  key_press("ArrowDown")

  expect_equal(app$get_value(input = "blur-num"), VALUE)
  key_press("Enter")
  VALUE <- 9
  expect_equal(app$get_value(input = "blur-num"), VALUE)

  app$click('blur-update_number')
  expect_equal(
    app$get_js("document.querySelector('#blur-num').value"),
    "42"
  )
  expect_equal(app$get_value(input = "blur-num"), VALUE)
  app$click('blur-update_number')
  expect_equal(
    app$get_js("document.querySelector('#blur-num').value"),
    "3.14159"
  )
  expect_equal(app$get_value(input = "blur-num"), VALUE)

  key_press("Enter")
  VALUE <- 3.14159
  expect_equal(app$get_value(input = "blur-num"), VALUE)
})

# ---- passwordInput() ---------------------------------------------------------
test_that("passwordInput() -- updateOn='change'", {
  VALUE <- "H3ll0"
  app$set_inputs("change-pwd" = VALUE, wait_ = FALSE)
  expect_equal(app$get_value(input = "change-pwd"), VALUE)

  app_focus_element(app, "#change-pwd")
  key_press("End")
  key_press_write("_w0r1d")

  # input has updated, even though it still has focus
  Sys.sleep(0.5)
  VALUE <- "H3ll0_w0r1d"
  expect_equal(app$get_value(input = "change-pwd"), VALUE)
  expect_js(app, "$('#change-pwd').is(':focus')")

  app$click("change-update_pwd")
  VALUE <- "Tr0ub4dor&3"
  expect_equal(app$get_value(input = "change-pwd"), VALUE)
})

test_that("passwordInput() -- updateOn='blur'", {
  VALUE <- "H3ll0"
  app$set_inputs("blur-pwd" = VALUE, wait_ = FALSE)
  expect_equal(app$get_value(input = "blur-pwd"), VALUE)

  app_focus_element(app, "#blur-pwd")
  key_press("End")
  key_press_write("_w0r1d")

  # input has not updated yet
  expect_equal(app$get_value(input = "blur-pwd"), VALUE)

  # input updates after blur
  app$get_js("$('#blur-pwd').blur()")
  VALUE <- "H3ll0_w0r1d"
  expect_equal(app$get_value(input = "blur-pwd"), VALUE)

  # input updates on Enter
  app_focus_element(app, "#blur-pwd")
  key_press("End")
  key_press_write("!")

  expect_equal(app$get_value(input = "blur-pwd"), VALUE)
  key_press("Enter")
  VALUE <- "H3ll0_w0r1d!"
  expect_equal(app$get_value(input = "blur-pwd"), VALUE)

  app$click('blur-update_pwd')
  expect_equal(
    app$get_js("document.querySelector('#blur-pwd').value"),
    "Tr0ub4dor&3"
  )
  expect_equal(app$get_value(input = "blur-pwd"), VALUE)
  app$click('blur-update_pwd')
  expect_equal(
    app$get_js("document.querySelector('#blur-pwd').value"),
    "P@ssw0rd123!"
  )
  expect_equal(app$get_value(input = "blur-pwd"), VALUE)

  key_press("Enter")
  VALUE <- "P@ssw0rd123!"
  expect_equal(app$get_value(input = "blur-pwd"), VALUE)
})

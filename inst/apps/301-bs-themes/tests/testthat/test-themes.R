library(bslib)

# Only run these tests on mac + r-release
# (To reduce the amount of screenshot diffing noise)
release <- rversions::r_release()$version
release <- paste0(
  strsplit(release, ".", fixed = TRUE)[[1]][1:2],
  collapse = "."
)
if (!identical(paste0("mac-", release), shinytest2::platform_variant())) {
  skip("Not mac + r-release")
}
if (length(dir("_snaps")) > 1) {
  stop("More than 1 _snaps folder found!")
}

themes <- list(
  default4 = list(version = 5),
  default4 = list(version = 4),
  custom5 = list(
    version = 5,
    bg = "#202123",
    fg = "#B8BCC2",
    primary = "#EA80FC",
    secondary = "#00DAC6",
    success = "#4F9B29",
    info = "#28B3ED",
    warning = "#FD7424",
    danger = "#F7367E",
    base_font = bslib::font_google("Open Sans"),
    heading_font = bslib::font_google("Proza Libre"),
    code_font = bslib::font_google("Fira Code")
  ),
  custom4 = list(
    version = 4,
    bg = "#202123",
    fg = "#B8BCC2",
    primary = "#EA80FC",
    secondary = "#00DAC6",
    success = "#4F9B29",
    info = "#28B3ED",
    warning = "#FD7424",
    danger = "#F7367E",
    base_font = bslib::font_google("Open Sans"),
    heading_font = bslib::font_google("Proza Libre"),
    code_font = bslib::font_google("Fira Code")
  )
)

for (theme_name in names(themes)) {
  theme <- themes[[theme_name]]
  if (!is_bs_theme(theme)) {
    theme <- do.call(bs_theme, theme)
  }

  test_that(paste0("theme: ", theme_name), {
    app <- AppDriver$new(
      name = theme_name,
      variant = shinytest2::platform_variant(),
      seed = 101,
      options = list(bslib_theme = theme, "shiny.json.digits" = 4)
    )
    withr::defer({ app$stop() })

    # I don't know why, but when calling `app$get_screenshot()`, the app gets wider and wider
    # Mitigating that by resetting the size each time. This is a hack, but it works.

    # app$view()
    # browser()

    cur_size <- app$get_window_size()
    reset_size <- function() {
      app$set_window_size(
        height = cur_size$height,
        width = cur_size$width,
        wait = TRUE
      )
    }

    appshot <- function() {
      app$expect_values()
      # Allow for a 10% difference in the screenshot kernel
      # 3000 / (3x RGB channels * 100 * 100) = 3000 / 30000 = 10%
      app$expect_screenshot(threshold = 3000, kernel_size = 100)
    }
    appshot()



    app$set_inputs(slider = c(30, 83))
    app$set_inputs(slider = c(14, 83))
    app$set_inputs(selectize = "AK")
    app$set_inputs(selectizeMulti = "AK")
    app$set_inputs(selectizeMulti = c("AK", "AR"))
    app$set_inputs(selectizeMulti = c("AK", "AR", "CO"))
    app$set_inputs(date = "2020-12-21")
    app$set_inputs(dateRange = c("2020-12-24", "2020-12-14"))
    app$set_inputs(dateRange = c("2020-12-24", "2020-12-26"))
    app$set_inputs(secondary = "click")
    appshot()

    app$set_inputs(inputs = "wellPanel()")
    app$set_inputs(select = "AZ")
    app$set_inputs(password = "secretdfdsf")
    app$set_inputs(textArea = "dsfsdf")
    app$set_inputs(text = "asfdsf")
    app$set_inputs(checkGroup = "A")
    app$set_inputs(check = FALSE)
    app$set_inputs(radioButtons = "B")
    app$set_inputs(numeric = 1)
    app$set_inputs(numeric = 2)
    app$set_inputs(numeric = 3)
    app$set_inputs(numeric = 4)
    appshot()

    app$set_inputs(navbar = "Plots", timeout_ = 10 * 1000)
    appshot()

    app$set_inputs(navbar = "Tables", timeout_ = 10 * 1000)
    app$wait_for_value(input = "DT_rows_current")
    appshot()

    app$set_inputs(navbar = "Fonts")
    appshot()

    app$set_inputs(navbar = "Notifications")
    app$set_inputs(otherNav = "Uploads & Downloads")
    app$upload_file(file = "upload-file.txt")
    appshot()

    app$run_js(script = "window.modalShown = false;\n  $(document).on('shown.bs.modal', function(e) { window.modalShown = true; });",
      timeout = 10000)
    app$set_inputs(showModal = "click")
    app$wait_for_js("window.modalShown", timeout = 3000)
    appshot()

    # It'd be nice to have snapshots of notifications and progress bars,
    # but I'm not sure if the timing issues they present are worth the maintainence cost
    #
    #app$set_inputs(showDefault = "click")
    #app$set_inputs(showMessage = "click")
    #app$set_inputs(showWarning = "click")
    #app$set_inputs(showError = "click")
    #app$set_inputs(navbar = "Options")
    #app$set_inputs(showProgress2 = "click", wait_ = FALSE, values_ = FALSE)
    # appshot()
  })
}

test_that("stable snapshot fonts are registered and exposed as CSS", {
  skip_if_not_installed("systemfonts")

  fonts <- shinycoreci:::coreci_snapshot_font_files()

  expect_named(
    fonts,
    c(
      "sans_regular",
      "sans_bold",
      "sans_italic",
      "sans_bolditalic",
      "mono_regular",
      "mono_bold"
    )
  )
  expect_true(all(file.exists(fonts)))

  css <- shinycoreci:::coreci_snapshot_font_css()
  expect_match(css, "@font-face", fixed = TRUE)
  expect_match(css, "CoreCI Sans", fixed = TRUE)
  expect_match(css, "CoreCI Mono", fixed = TRUE)

  shinycoreci:::coreci_snapshot_register_fonts()
  expect_identical(systemfonts::match_fonts("sans")$path, fonts[["sans_regular"]])
  expect_identical(systemfonts::match_fonts("CoreCI Sans")$path, fonts[["sans_regular"]])
})

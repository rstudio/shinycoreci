test_that("stable snapshot fonts are registered and exposed as CSS", {
  skip_if_not_installed("systemfonts")

  fonts <- ci_snapshot_font_files()

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

  css <- ci_snapshot_font_css()
  expect_match(css, "@font-face", fixed = TRUE)
  expect_match(css, "CoreCI Sans", fixed = TRUE)
  expect_match(css, "CoreCI Mono", fixed = TRUE)

  ci_snapshot_register_fonts()
  expect_identical(systemfonts::match_fonts("sans")$path, fonts[["sans_regular"]])
  expect_identical(systemfonts::match_fonts("CoreCI Sans")$path, fonts[["sans_regular"]])
})

test_that("stable snapshot bootstrap does not patch shinytest2 internals", {
  skip_if_not_installed("shinytest2")

  ns <- asNamespace("shinytest2")
  original_start <- get("app_start_shiny", ns)
  original_initialize <- shinytest2::AppDriver$public_methods$initialize

  ci_setup_consistent_snapshots()

  expect_identical(get("app_start_shiny", ns), original_start)
  expect_identical(shinytest2::AppDriver$public_methods$initialize, original_initialize)
})

test_that("stable snapshot options preserve explicit graphics choices", {
  expect_identical(
    ci_snapshot_merge_shiny_options(NULL),
    list(shiny.useragg = TRUE)
  )
  expect_identical(
    ci_snapshot_merge_shiny_options(list(shiny.useragg = FALSE, shiny.usecairo = TRUE)),
    list(shiny.useragg = FALSE, shiny.usecairo = TRUE)
  )
})

test_that("stable snapshot variants split mutable macOS runner majors", {
  expect_identical(
    ci_snapshot_variant("mac-4.6", running = "macOS Sequoia 15.7.7"),
    "mac-4.6-macos-15"
  )
  expect_identical(
    ci_snapshot_variant("mac-4.6", running = "macOS Tahoe 26.4"),
    "mac-4.6-macos-26"
  )
  expect_identical(
    ci_snapshot_variant("linux-4.6", running = "Ubuntu 24.04.3 LTS"),
    "linux-4.6"
  )
  expect_identical(
    ci_snapshot_variant("custom-mac-variant", running = "macOS Tahoe 26.4"),
    "custom-mac-variant"
  )
  expect_null(ci_snapshot_variant(NULL, running = "macOS Tahoe 26.4"))
})

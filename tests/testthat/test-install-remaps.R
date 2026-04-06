test_that("package refs are remapped for older macOS R", {
  expect_identical(
    remap_pkg_refs(
      c("htmltools", "later", "shiny"),
      platform_val = "mac",
      r_version = "4.2.3"
    ),
    c("cran::htmltools", "cran::later", "shiny")
  )
})

test_that("package refs are unchanged for newer macOS R", {
  expect_identical(
    remap_pkg_refs(
      c("htmltools", "later", "shiny"),
      platform_val = "mac",
      r_version = "4.3.0"
    ),
    c("htmltools", "later", "shiny")
  )
})

test_that("archived package remaps are preserved", {
  expect_identical(
    remap_pkg_refs(
      c("plogr", "pryr", "shiny"),
      platform_val = "linux",
      r_version = "4.5.0"
    ),
    c("krlmlr/plogr", "hadley/pryr", "shiny")
  )
})
test_that("package refs are remapped for older macOS R", {
  expect_identical(
    remap_pkg_refs(
      c("bsicons", "crosstalk", "htmltools", "later", "shiny", "shinyjster"),
      platform_val = "mac",
      r_version = "4.2.3"
    ),
    c(
      "rstudio/bsicons",
      "rstudio/crosstalk",
      "cran::htmltools",
      "cran::later",
      "shiny",
      "schloerke/shinyjster"
    )
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

clear_installed_pkg_cache <- function() {
  rm(list = ls(envir = installed_pkgs, all.names = TRUE), envir = installed_pkgs)
}

test_that("packages already installed in the libpath are skipped", {
  clear_installed_pkg_cache()
  withr::defer(clear_installed_pkg_cache())

  install_calls <- list()

  testthat::local_mocked_bindings(
    get_extra_shinyverse_deps = function(packages) character(),
    is_installed = function(package, libpath) package %in% c("htmltools", "later"),
    install_pkgs_with_callr = function(packages, ..., libpath = .libPaths()[1], upgrade = TRUE, dependencies = NA, verbose = TRUE) {
      install_calls[[length(install_calls) + 1]] <<- packages
    },
    .package = "shinycoreci"
  )

  install_missing_pkgs(
    c("htmltools", "later", "shiny"),
    libpath = tempfile("lib-"),
    verbose = FALSE
  )

  expect_identical(install_calls, list("shiny"))
})

test_that("macOS oldrel CRAN pins are installed before the remaining packages", {
  clear_installed_pkg_cache()
  withr::defer(clear_installed_pkg_cache())

  install_calls <- list()
  installed_now <- character()

  testthat::local_mocked_bindings(
    get_extra_shinyverse_deps = function(packages) character(),
    is_installed = function(package, libpath) package %in% installed_now,
    macos_oldrel_pkg_refs = function(platform_val = platform(), r_version = getRversion()) {
      c(
        "htmltools" = "cran::htmltools",
        "later" = "cran::later",
        "shinyjster" = "schloerke/shinyjster"
      )
    },
    install_pkgs_with_callr = function(packages, ..., libpath = .libPaths()[1], upgrade = TRUE, dependencies = NA, verbose = TRUE) {
      install_calls[[length(install_calls) + 1]] <<- packages

      if (identical(packages, c("cran::htmltools", "cran::later", "schloerke/shinyjster"))) {
        installed_now <<- c(installed_now, "htmltools", "later", "shinyjster")
      }
    },
    .package = "shinycoreci"
  )

  install_missing_pkgs(
    c("htmltools", "later", "shiny", "shinyjster"),
    libpath = tempfile("lib-"),
    verbose = FALSE
  )

  expect_identical(
    install_calls,
    list(c("cran::htmltools", "cran::later", "schloerke/shinyjster"), "shiny")
  )
})
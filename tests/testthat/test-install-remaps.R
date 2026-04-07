test_that("r-universe is excluded from repos on old macOS R", {
  repos_old <- shinyverse_repos_option(platform_val = "mac", r_version = "4.2.3")
  expect_false(shinyverse_cran_url %in% repos_old)

  repos_new <- shinyverse_repos_option(platform_val = "mac", r_version = "4.3.0")
  expect_true(shinyverse_cran_url %in% repos_new)
})

test_that("package refs are remapped for older macOS R", {
  remapped <- remap_pkg_refs(
    c("bsicons", "crosstalk", "htmltools", "later", "shiny", "shinyjster",
      "plotly", "leaflet", "DT"),
    platform_val = "mac",
    r_version = "4.2.3"
  )
  expect_identical(
    remapped,
    c(
      "rstudio/bsicons",
      "rstudio/crosstalk",
      "cran::htmltools",
      "cran::later",
      "rstudio/shiny",
      "schloerke/shinyjster",
      "ropensci/plotly",
      "rstudio/leaflet",
      "rstudio/DT"
    )
  )
  # shinycoreci should NOT be remapped (installed from checkout)
  expect_identical(
    remap_pkg_refs("shinycoreci", platform_val = "mac", r_version = "4.2.3"),
    "shinycoreci"
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

test_that("macOS oldrel pinned packages are installed before the remaining packages", {
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
        "bslib" = "rstudio/bslib",
        "plotly" = "ropensci/plotly",
        "shiny" = "rstudio/shiny",
        "shinyjster" = "schloerke/shinyjster"
      )
    },
    install_pkgs_with_callr = function(packages, ..., libpath = .libPaths()[1], upgrade = TRUE, dependencies = NA, verbose = TRUE) {
      install_calls[[length(install_calls) + 1]] <<- packages

      pinned_refs <- c("cran::htmltools", "cran::later", "rstudio/bslib",
                       "ropensci/plotly", "rstudio/shiny", "schloerke/shinyjster")
      if (all(packages %in% pinned_refs)) {
        installed_now <<- c(installed_now, "htmltools", "later", "bslib",
                           "plotly", "shiny", "shinyjster")
      }
    },
    .package = "shinycoreci"
  )

  install_missing_pkgs(
    c("bslib", "htmltools", "later", "plotly", "shiny", "shinyjster", "withr"),
    libpath = tempfile("lib-"),
    verbose = FALSE
  )

  # First call: all shinyverse pkgs via pinned refs; second call: remaining CRAN pkgs
  expect_length(install_calls, 2)
  expect_identical(
    sort(install_calls[[1]]),
    sort(c("cran::htmltools", "cran::later", "rstudio/bslib",
           "ropensci/plotly", "rstudio/shiny", "schloerke/shinyjster"))
  )
  expect_identical(install_calls[[2]], "withr")
})
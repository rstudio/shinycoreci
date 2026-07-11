test_that("loaded packages are matched to the requested library", {
  loaded_path <- getNamespaceInfo("shinycoreci", "path")

  expect_true(is_loaded_from_libpath("shinycoreci", dirname(loaded_path)))

  other_lib <- tempfile()
  dir.create(other_lib)
  expect_false(is_loaded_from_libpath("shinycoreci", other_lib))
})

test_that("archived packages are remapped before dependency discovery", {
  discovered <- NULL
  install_env <- environment(install_missing_pkgs)

  testthat::local_mocked_bindings(
    get_extra_shinyverse_deps = function(packages) {
      discovered <<- packages
      character()
    },
    install_pkgs_with_callr = function(...) invisible(),
    .env = install_env
  )

  install_missing_pkgs("pryr")

  expect_identical(discovered, "hadley/pryr")
})

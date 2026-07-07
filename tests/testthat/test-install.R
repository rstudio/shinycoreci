test_that("loaded packages are matched to the requested library", {
  loaded_path <- getNamespaceInfo("shinycoreci", "path")

  expect_true(is_loaded_from_libpath("shinycoreci", dirname(loaded_path)))

  other_lib <- tempfile()
  dir.create(other_lib)
  expect_false(is_loaded_from_libpath("shinycoreci", other_lib))
})

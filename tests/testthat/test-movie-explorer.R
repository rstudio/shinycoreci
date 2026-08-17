test_that("051-movie-explorer dependencies do not include RSQLite", {
  deps <- shinycoreci:::apps_deps_map[["051-movie-explorer"]]
  expect_false("RSQLite" %in% deps)
  expect_false("DBI" %in% deps)
})

test_that("051-movie-explorer dataset loads properly", {
  rds_path <- system.file(
    "apps/051-movie-explorer/movies.rds",
    package = "shinycoreci"
  )
  if (!nzchar(rds_path)) {
    rds_path <- file.path(
      rprojroot::find_package_root_file(),
      "inst/apps/051-movie-explorer/movies.rds"
    )
  }
  expect_true(file.exists(rds_path))

  movies <- readRDS(rds_path)
  expect_s3_class(movies, "data.frame")
  expect_true(nrow(movies) > 0)
  cols <- c("ID", "Title", "Year", "Genre", "Oscars", "Reviews", "BoxOffice")
  expect_true(all(cols %in% names(movies)))
})

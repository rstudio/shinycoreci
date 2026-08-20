test_that("051-movie-explorer dependencies do not include RSQLite", {
  deps <- shinycoreci:::apps_deps_map[["051-movie-explorer"]]
  expect_false("RSQLite" %in% deps)
  expect_false("DBI" %in% deps)
})

test_that("051-movie-explorer reads CSV columns with explicit types", {
  app_dir <- system.file("apps/051-movie-explorer", package = "shinycoreci")
  if (!nzchar(app_dir)) {
    app_dir <- file.path(
      rprojroot::find_package_root_file(),
      "inst/apps/051-movie-explorer"
    )
  }

  fixture_dir <- withr::local_tempdir()
  file.copy(file.path(app_dir, "server.R"), fixture_dir)
  writeLines(
    c(
      paste(
        c(
          "ID", "imdbID", "Title", "Year", "Rating_m", "Runtime", "Genre",
          "Released", "Director", "Writer", "imdbRating", "imdbVotes",
          "Language", "Country", "Oscars", "Rating", "Meter", "Reviews",
          "Fresh", "Rotten", "userMeter", "userRating", "userReviews",
          "BoxOffice", "Production", "Cast"
        ),
        collapse = ","
      ),
      paste(
        c(
          "1", "tt0000001", "Example", "2000", "PG", "90.5", "Drama",
          "2000-01-01", "Director", "Writer", "7.5", "123", "English",
          "USA", "1", "8.1", "90", "12", "10", "2", "80.5", "4.1",
          "100", "1000000", "Studio", "Actor"
        ),
        collapse = ","
      )
    ),
    file.path(fixture_dir, "movies.csv")
  )

  app_env <- new.env(parent = globalenv())
  app_env$library <- function(...) invisible(NULL)
  load_error <- tryCatch(
    {
      source(file.path(fixture_dir, "server.R"), local = app_env, chdir = TRUE)
      NULL
    },
    error = identity
  )
  expect_null(load_error)
  if (!is.null(load_error)) {
    return(invisible())
  }

  expect_identical(
    vapply(app_env$all_movies, typeof, character(1)),
    c(
      ID = "integer", imdbID = "character", Title = "character",
      Year = "integer", Rating_m = "character", Runtime = "double",
      Genre = "character", Released = "character", Director = "character",
      Writer = "character", imdbRating = "double", imdbVotes = "double",
      Language = "character", Country = "character", Oscars = "integer",
      Rating = "double", Meter = "integer", Reviews = "integer",
      Fresh = "integer", Rotten = "integer", userMeter = "double",
      userRating = "double", userReviews = "double", BoxOffice = "double",
      Production = "character", Cast = "character"
    )
  )
})

test_that("051-movie-explorer dataset loads properly", {
  csv_path <- system.file(
    "apps/051-movie-explorer/movies.csv",
    package = "shinycoreci"
  )
  if (!nzchar(csv_path)) {
    csv_path <- file.path(
      rprojroot::find_package_root_file(),
      "inst/apps/051-movie-explorer/movies.csv"
    )
  }
  expect_true(file.exists(csv_path))
  if (!file.exists(csv_path)) {
    return(invisible())
  }

  movies <- read.csv(csv_path, stringsAsFactors = FALSE)
  expect_s3_class(movies, "data.frame")
  expect_equal(nrow(movies), 12569)
  cols <- c("ID", "Title", "Year", "Genre", "Oscars", "Reviews", "BoxOffice")
  expect_true(all(cols %in% names(movies)))
})

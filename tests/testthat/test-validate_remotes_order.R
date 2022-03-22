


test_that("remotes are in correct order", {
  skip_on_cran()
  skip_on_ci() # tested in routine.yml workflow

  # do not expect this to error
  expect_error({
    validate_remotes_order()
  }, NA)
})

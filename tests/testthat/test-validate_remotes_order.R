


test_that("remotes are in correct order", {
  # do not expect this to error
  expect_error({
    validate_remotes_order()
  }, NA)
})

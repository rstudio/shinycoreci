
test_that("reactives update", {
  testServer(expr = {
    session$setInputs(bins = 5)
    expect_equal(bins(), seq(43, 96, length.out = 6))
  })
})

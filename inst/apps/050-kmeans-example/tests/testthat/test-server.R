testServer(expr = {
  test_that("it works", {
    session$setInputs(
      xcol = "Sepal.Length",
      ycol = "Petal.Length",
      clusters = 4
    )
    expect_equal(colnames(selectedData()), c("Sepal.Length", "Petal.Length"))
    expect_equal(nrow(clusters()$centers), 4)
    session$setInputs(clusters = 3)
    expect_equal(nrow(clusters()$centers), 3)
  })
})

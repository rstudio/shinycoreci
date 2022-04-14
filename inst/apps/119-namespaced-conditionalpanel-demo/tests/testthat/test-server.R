test_that("app works", {
  testServer(expr = {
    session$setInputs(`plot1-n` = 4)
    plot4 <- output$`plot1-scatterPlot`
    expect_true(!is.null(plot4))

    session$setInputs(`plot1-n` = 8)
    plot8 <- output$`plot1-scatterPlot`
    expect_true(!is.null(plot8))
    expect_true(!identical(plot4, plot8))
  })
})

testServer(expr = {
  session$flushReact()
  expect_equal(output$text, "File load order: C, b, á")
})

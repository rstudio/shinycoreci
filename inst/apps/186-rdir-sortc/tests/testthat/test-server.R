testServer(expr = {
  session$flushReact()
  expect_equal(output$text, "File load order: B_, C, b")
})

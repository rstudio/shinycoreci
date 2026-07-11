function(input, output) {

  output$scatterPlot <- renderPlot({
    set.seed(100)
    x <- rnorm(input$n)
    y <- rnorm(input$n)
    plot(x, y)
  })

}

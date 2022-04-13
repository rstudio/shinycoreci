function(input, output) {
  output$plot1 <- renderPlot({
    hist(
      rnorm(input$n),
      # color,border is added to allow for <= Rv3.6 (white) to match >= Rv 4.0 (grey)
      col = "white", border = "grey"
    )
  })

  output$textout <- renderText({
    paste("Input text is:", input$text)
  })
}

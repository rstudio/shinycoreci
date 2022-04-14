### Keep this line to manually test this shiny application. Do not edit this line; shinycoreci::::is_manual_app


function(input, output) {

  output$actionOut <- renderPrint({ input$action })
  output$checkboxOut <- renderPrint({ input$checkbox })
  output$checkGroupOut <- renderPrint({ input$checkGroup })
  output$dateOut <- renderPrint({ input$date })
  output$datesOut <- renderPrint({ input$dates })
  output$fileOut <- renderPrint({
    if (is.null(input$file))
      return(NULL)
    df <- input$file
    df$datapath <- paste0("<tempdir>/", basename(df$datapath))
    df
  })
  output$numOut <- renderPrint({ input$num })
  output$radioOut <- renderPrint({ input$radio })
  output$selectOut <- renderPrint({ input$select })
  output$slider1Out <- renderPrint({ input$slider1 })
  output$slider2Out <- renderPrint({ input$slider2 })
  #output$submitOut <- renderPrint({ input$submit })
  output$textOut <- renderPrint({ input$text })

}

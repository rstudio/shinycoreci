### Keep this line to manually test this shiny application. Do not edit this line; shinycoreci::::is_manual_app


library(shiny)

# Define UI for app that draws a histogram ----
ui <- fluidPage(

  # App title ----
  titlePanel("Hello Shiny!"),

  # Sidebar layout with input and output definitions ----
  sidebarLayout(

    # Sidebar panel for inputs ----
    sidebarPanel(

      # Input: Slider for the number of bins ----
      sliderInput(inputId = "bins",
                  label = "Number of bins:",
                  min = 1,
                  max = 50,
                  value = 30)

    ),

    # Main panel for displaying outputs ----
    mainPanel(

      # Output: Histogram ----
      plotOutput(outputId = "distPlot")

    )
  ),

  # include shinyjster JS at end of UI definition
  shinyjster::shinyjster_js("
    var jst = jster();
    jst.add(Jster.shiny.waitUntilStable);
    jst.add(Jster.shiny.waitUntilIdleFor(1000));
    var img30;

    jst.add(function(){
      Jster.assert.isEqual(Jster.slider.getValue('bins'), 30);

      // convert to character string
      img30 = JSON.stringify(Jster.image.data('distPlot'));

      Jster.slider.setValue('bins',10);
    });

    jst.add(Jster.shiny.waitUntilStable);
    jst.add(Jster.shiny.waitUntilIdleFor(1000));
    jst.add(function(){
      Jster.assert.isEqual(Jster.slider.getValue('bins'), 10);
      var img10 = JSON.stringify(Jster.image.data('distPlot'));
      Jster.assert.isTrue(img30 !== img10, {xbins: 30, ybins: 10});
    });

    jst.test();
  ")
)

# Define server logic required to draw a histogram ----
server <- function(input, output, session) {

  # include shinyjster_server call at top of server definition
  shinyjster::shinyjster_server(input, output)

  x <- faithful$waiting

  bins <- reactive({
    seq(min(x), max(x), length.out = input$bins + 1)
  })

  output$distPlot <- renderPlot({

    hist(x, breaks = bins(), col = "#75AADB", border = "white",
         xlab = "Waiting time to next eruption (in mins)",
         main = "Histogram of waiting times")

    })

}


# Create Shiny app ----
shinyApp(ui = ui, server = server)

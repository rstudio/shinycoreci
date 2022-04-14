library(shiny)

# Define UI for dataset viewer app ----
ui <- fluidPage(

  # App title ----
  titlePanel("Shiny Text"),

  # Sidebar layout with a input and output definitions ----
  sidebarLayout(

    # Sidebar panel for inputs ----
    sidebarPanel(

      # Input: Selector for choosing dataset ----
      selectInput(inputId = "dataset",
                  label = "Choose a dataset:",
                  choices = c("rock", "pressure", "cars")),

      # Input: Numeric entry for number of obs to view ----
      numericInput(inputId = "obs",
                   label = "Number of observations to view:",
                   value = 10)
    ),

    # Main panel for displaying outputs ----
    mainPanel(

      # Output: Verbatim text for data summary ----
      verbatimTextOutput("summary"),

      # Output: HTML table with requested number of observations ----
      tableOutput("view")

    )
  ),

  # include shinyjster JS at end of UI definition
  shinyjster::shinyjster_js("
    var jst = jster(1);
    jst.add(Jster.shiny.waitUntilStable);

    jst.add(function() {
    // title
    Jster.assert.isEqual($('h2').first().html(),'Shiny Text');

    // dropdown input
    Jster.assert.isEqual(Jster.selectize.label('dataset'),'Choose a dataset:');
    });

    var infos=[
        {dataset:'rock',headerValues:['area', 'peri', 'shape', 'perm']},
        {dataset:'pressure',headerValues:['temperature','pressure']},
        {dataset:'cars',headerValues:['speed','dist']}
    ];

    infos.map(function(info,idx){
      jst.add(Jster.shiny.waitUntilStable);
      jst.add(function() {
        Jster.selectize.click('dataset');
      });
      jst.add(Jster.shiny.waitUntilStable);

      jst.add(function() {
        // click
        Jster.selectize.clickOption('dataset',idx);
      });
      jst.add(Jster.shiny.waitUntilStable);
      jst.add(Jster.shiny.waitUntilStable);

      jst.add(function() {

        Jster.assert.isEqual(Jster.selectize.currentOption('dataset'),info.dataset);

        // Second input box
        Jster.assert.isEqual(Jster.input.label('obs'),'Number of observations to view:');
        Jster.assert.isEqual(Jster.input.currentOption('obs'),'10');

        // table headers
        var tableHeaderValues = info.headerValues;
        $('#view th').map(function(idx, val) {
            var tableHeader = $(val).text().trim();
            Jster.assert.isEqual(tableHeader,tableHeaderValues[idx]);
        });

        // Summary id
        var summaryHeaderText = $('#summary').text().split('\\n')[0];
        $.trim(summaryHeaderText).split(/ +/g).map(function(val, idx) {
            Jster.assert.isEqual(val,tableHeaderValues[idx]);
        });
      });
    });
    jst.test();
  ")

)

# Define server logic to summarize and view selected dataset ----
server <- function(input, output) {
  # include shinyjster_server call at top of server definition
  shinyjster::shinyjster_server(input, output)

  # Return the requested dataset ----
  datasetInput <- reactive({
    switch(input$dataset,
           "rock" = rock,
           "pressure" = pressure,
           "cars" = cars)
  })

  # Generate a summary of the dataset ----
  output$summary <- renderPrint({
    dataset <- datasetInput()
    summary(dataset)
  })

  # Show the first "n" observations ----
  output$view <- renderTable({
    head(datasetInput(), n = input$obs)
  })

}


# Create Shiny app ----
shinyApp(ui = ui, server = server)

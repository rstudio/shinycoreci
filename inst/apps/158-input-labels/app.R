library(shiny)

# ensure two column appear on small displays
column2 <- function(x) {
  div(class = "col-xs-6", x)
}

row <- function(w1, w2) {
  fluidRow(column2(w1), column2(w2))
}

label_initial <- "An <i>escaped</i> Label"

ui <- fluidPage(
  p("Everytime you click on the button below, it should add labels to the column that doesn't (currently) have labels, and remove labels from the column that does (currently) have labels. Every label should say: '", tags$b(label_initial, .noWS = "outside"), "'."),
  p(
    a(href = "https://github.com/rstudio/shiny/pull/2406", "PR #2406"), ", ",
    a(href = "https://github.com/rstudio/shiny/issues/868", "Issue #868")
  ),
  actionButton("update", "Add/remove labels"),
  hr(),
  row(
    textInput("textInput1", label = NULL),
    textInput("textInput2", label = label_initial)
  ),
  row(
    textAreaInput("textAreaInput1", label = NULL),
    textAreaInput("textAreaInput2", label = label_initial)
  ),
  row(
    numericInput("numericInput1", label = NULL, value = 1),
    numericInput("numericInput2", label = label_initial, value = 1)
  ),
  row(
    sliderInput("sliderInput1", label = NULL, value = 1, min = 0, max = 1),
    sliderInput("sliderInput2", label = label_initial, value = 1, min = 0, max = 1)
  ),
  row(
    passwordInput("passwordInput1", label = NULL),
    passwordInput("passwordInput2", label = label_initial)
  ),
  row(
    selectInput("selectInput1", label = NULL, choices = "a", selectize = FALSE),
    selectInput("selectInput2", label = label_initial, choices = "a", selectize = FALSE)
  ),
  row(
    selectizeInput("selectizeInput1", label = NULL, choices = "a"),
    selectizeInput("selectizeInput2", label = label_initial, choices = "a")
  ),
  row(
    varSelectInput("varSelectInput1", label = NULL, data = iris),
    varSelectInput("varSelectInput2", label = label_initial, data = iris)
  ),
  row(
    varSelectizeInput("varSelectizeInput1", label = NULL, data = iris),
    varSelectizeInput("varSelectizeInput2", label = label_initial, data = iris)
  ),
  row(
    checkboxInput("checkboxInput1", label = NULL),
    checkboxInput("checkboxInput2", label = label_initial)
  ),
  row(
    checkboxGroupInput("checkboxGroupInput1", label = NULL, choices = "a"),
    checkboxGroupInput("checkboxGroupInput2", label = label_initial, choices = "a")
  ),
  row(
    dateInput("dateInput1", label = NULL, value = "2020-02-01"),
    dateInput("dateInput2", label = label_initial, value = "2020-02-01")
  ),
  shinyjster::shinyjster_js("
    var jst = jster();
    jst.add(Jster.shiny.waitUntilStable);

    var check_labels = function(num, label) {
      var check_label_val = function(name, x) {
        Jster.assert.isEqual(
          x,
          label,
          {name: name, label: label}
        );
      }
      var check_label = function(name) {
        name = '' + name + num;
        check_label_val(name, $('label[for=\"' + name + '\"]:visible').text().trim());
      }
      var check_selectize_label = function(name) {
        name = '' + name + num;
        check_label_val(name, Jster.selectize.label(name));
      }
      var check_checkbox_label = function(name) {
        name = '' + name + num;
        check_label_val(name, Jster.checkbox.label(name));
      }
      check_label('textInput');
      check_label('textAreaInput');
      check_label('numericInput');
      check_label('sliderInput');
      check_label('passwordInput');
      check_label('selectInput');
      check_selectize_label('selectizeInput');
      check_selectize_label('varSelectInput');
      check_selectize_label('varSelectizeInput');
      check_checkbox_label('checkboxInput');
      check_label('checkboxGroupInput');
      check_label('dateInput');
    };

    jst.add(function() {
      check_labels(1, '');
      check_labels(2, 'An <i>escaped</i> Label');

      Jster.button.click('update');
    });
    jst.add(Jster.shiny.waitUntilStable);

    jst.add(function() {
      check_labels(1, 'An <i>escaped</i> Label');
      check_labels(2, '');

      Jster.button.click('update');
    });

    jst.add(Jster.shiny.waitUntilStable);
    jst.add(function() {
      check_labels(1, '');
      check_labels(2, 'An <i>escaped</i> Label');
    });

    jst.test();
  ")
)


server <- function(input, output, session) {
  shinyjster::shinyjster_server(input, output, session)

  observeEvent(input$update, {
    label1 <- if (isTRUE(input$update %% 2 == 0)) character(0) else "An <i>escaped</i> Label"
    updateTextInput(session, "textInput1", label = label1)
    updateTextAreaInput(session, "textAreaInput1", label = label1)
    updateNumericInput(session, "numericInput1", label = label1)
    updateSliderInput(session, "sliderInput1", label = label1)
    updateTextInput(session, "passwordInput1", label = label1)
    updateSelectInput(session, "selectInput1", label = label1)
    updateSelectizeInput(session, "selectizeInput1", label = label1)
    updateVarSelectInput(session, "varSelectInput1", label = label1)
    updateVarSelectizeInput(session, "varSelectizeInput1", label = label1)
    updateCheckboxInput(session, "checkboxInput1", label = label1)
    updateCheckboxGroupInput(session, "checkboxGroupInput1", label = label1)
    updateDateInput(session, "dateInput1", label = label1)

    label2 <- if (isTRUE(input$update %% 2 > 0)) character(0) else "An <i>escaped</i> Label"
    updateTextInput(session, "textInput2", label = label2)
    updateTextAreaInput(session, "textAreaInput2", label = label2)
    updateNumericInput(session, "numericInput2", label = label2)
    updateSliderInput(session, "sliderInput2", label = label2)
    updateTextInput(session, "passwordInput2", label = label2)
    updateSelectInput(session, "selectInput2", label = label2)
    updateSelectizeInput(session, "selectizeInput2", label = label2)
    updateVarSelectInput(session, "varSelectInput2", label = label2)
    updateVarSelectizeInput(session, "varSelectizeInput2", label = label2)
    updateCheckboxInput(session, "checkboxInput2", label = label2)
    updateCheckboxGroupInput(session, "checkboxGroupInput2", label = label2)
    updateDateInput(session, "dateInput2", label = label2)
  })

}

shinyApp(ui, server)

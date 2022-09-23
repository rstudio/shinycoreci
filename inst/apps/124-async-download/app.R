library(shiny)
library(promises)
library(future)
plan(multiprocess)

ui <- fluidPage(
  h2("Async downloadHandler test"),
  tags$ol(
    tags$li("Verify that plot appears below"),
    tags$li("Verify that pressing Download results in 3 second delay, then rock.csv being downloaded"),
    tags$li("Check 'Throw on download?' checkbox and verify that pressing Download results in 3 second delay, then error, as well as stack traces in console")
  ),
  hr(),
  checkboxInput("throw", "Throw on download?"),
  downloadButton("download", "Download (wait 3 seconds)"),
  plotOutput("plot"),
  shinyjster::shinyjster_js("
    var jst = jster();

    var resetApp = function() {
      jst.add(Jster.shiny.waitUntilIdle);
      jst.add(function() {
        // make sure 'throw' is off
        if (Jster.checkbox.isChecked('throw')) {
          Jster.checkbox.click('throw')
        }
      });
      jst.add(Jster.shiny.waitUntilIdle);
    }

    var assertSuccess = function(done) {
      return function(error, value) {
        Jster.assert.isEqual(error, null);
        Jster.assert.isTrue(value.length > 100);
        done();
      }
    }
    var assertError = function(done) {
      return function(error, value) {
        Jster.assert.isEqual(value, null);
        Jster.assert.isEqual(error.textStatus, 'error');
        done();
      }
    }

    resetApp();
    jst.add(function(done) {
      console.log('regular download');
      Jster.assert.isFalse(Jster.checkbox.isChecked('throw'));
      //check regular download
      Jster.download.click('download', assertSuccess(done));
    });

    resetApp();
    jst.add(function() {
      console.log('error download');
      Jster.assert.isFalse(Jster.checkbox.isChecked('throw'));
      //check error download
      Jster.checkbox.click('throw');
    });
    jst.add(Jster.shiny.waitUntilIdle);
    jst.add(function(done) {
      Jster.download.click('download', assertError(done));
    })

    resetApp();
    jst.add(function(done) {
      Jster.assert.isFalse(Jster.checkbox.isChecked('throw'));
      console.log('regular, delayed checks, download');

      // check regular download,
      // change 'throw' to 'on' at 0.5 and and 'off' 1.5 seconds in
      setTimeout(function() {
        Jster.checkbox.click('throw'); // on
      }, 500);
      setTimeout(function() {
        Jster.checkbox.click('throw'); // off
      }, 1500);
      Jster.download.click('download', assertSuccess(done));
    });

    resetApp();
    jst.add(function(done) {
      Jster.assert.isFalse(Jster.checkbox.isChecked('throw'));
      console.log('success, delayed check, download');

      // check delayed error download,
      // change 'throw' to 'on' at 0.5 seconds in
      setTimeout(function() {
        Jster.checkbox.click('throw');
      }, 500);
      Jster.download.click('download', assertSuccess(done));
    });

    resetApp();
    jst.add(function() {
      Jster.assert.isFalse(Jster.checkbox.isChecked('throw'));
      console.log('error, delayed uncheck, download');

      // check delayed error download,
      // change 'throw' to 'on' at 0.5 seconds in
      Jster.checkbox.click('throw');
    });
    jst.add(Jster.shiny.waitUntilIdle);
    jst.add(function(done) {
      Jster.assert.isTrue(Jster.checkbox.isChecked('throw'));
      setTimeout(function() {
        Jster.checkbox.click('throw');
      }, 500);
      Jster.download.click('download', assertError(done));
    });

    jst.test();
  ")
)

server <- function(input, output, session) {
  # include shinyjster_server call at top of server definition
  shinyjster::shinyjster_server(input, output, session)

  output$download <- downloadHandler("rock.csv", function(file) {
    future({Sys.sleep(2)}) %...>%
    {
      if (input$throw) {
        stop("boom")
      } else {
        write.csv(rock, file)
      }
    }
  })

  output$plot <- renderPlot({
    plot(cars)
  })
}

shinyApp(ui, server)

function(input, output, session) {
  shinyjster::shinyjster_server(input, output, session)

  output$status <- renderPrint({
    tags$b("pass", style = "color: green;")
  })

  output$jster_ui <- renderUI({
    shinyjster::shinyjster_js("
      var jst = jster();

      jst.add(function(done) {
        var wait = function() {
          if (
            $(document.documentElement).hasClass('shiny-busy')
          ) {
            setTimeout(wait, 100);
            return;
          }
          done();
        }
        wait();
      });
      jst.add(function() {
        Jster.assert.isEqual(
          $('#status').text().trim(),
          'pass'
        );
      });

      jst.test();
    ")
  })
}

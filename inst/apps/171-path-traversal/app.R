shinyApp(
  fluidPage(
    p(
      "Click on each of the links below. They should report that the file is not found, or is forbidden.",
      "(For issues ", a("httpuv#235", href = "https://github.com/rstudio/httpuv/pull/235"),
      "and ", a("shiny#2566", href = "https://github.com/rstudio/shiny/pull/2566", .noWS = "after"), ")",
    ),
    a("Link 1", id="link1", href = "/shared/..%5c..%5c..%5c..%5c..%5c..%5c..%5c..%5c..%5cwindows%5cwin.ini"),
    br(),
    a("Link 2", id="link2", href = "/shared/../../../../../../../../etc/passwd"),
    shinyjster::shinyjster_js("
      var jst = jster();

      [
        'link1',
        'link2'
      ].map(function(id) {
        jst.add(function(done) {
          $.ajax({
            url: $('#' + id).attr('href'),
            error: function(error_info) {
              if (error_info.status == 404) {
                Jster.assert.isEqual('not found', 'not found');
              } else {
                Jster.assert.isEqual(
                  'unknown', 'not found',
                  {
                    error_info: error_info
                  }
                );
              }
            },
            success: function() {
              Jster.assert.isEqual('found', 'not found');
            },
            complete: function() {
              done();
            }
          });
        });
      });

      jst.test();
    ")
  ),
  function(input, output) {
    shinyjster::shinyjster_server(input, output)

  }
)

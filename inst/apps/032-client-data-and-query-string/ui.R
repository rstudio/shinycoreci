table_from_items <- function(...) {
  items <- list(...)
  tags$table(
    lapply(
      seq(from = 1, to = length(items) - 1, by = 2),
      function(i) {
        tags$tr(
          tags$td(items[[i]]),
          tags$td(items[[i + 1]])
        )
      }
    )
  )
}

parsed_url_singleton <- singleton(
  h3("Parsed URL query string")
)

fluidPage(
  titlePanel("Client data and query string example"),

  fluidRow(
    column(8,
      HTML("
        <p>The <code>session$clientdata</code> object provides the server with some information about the client.</p>
        <p>If the client is visiting a URL with a query string or hash (such as <code>http://localhost:8100/?a=xxx&b=yyy#zzz</code>), there will be values for <code>url_search</code> and <code>url_hash_initial</code>. This app will also display the parsed query string.</p>"),
      tags$br(),
      parsed_url_singleton,
      parsed_url_singleton,
      verbatimTextOutput("queryText", placeholder = TRUE),
      h3("session$clientdata values"),
      table_from_items(
        "pixelratio:", verbatimTextOutput("pixelratio", placeholder = TRUE),
        "singletons:", verbatimTextOutput("singletons", placeholder = TRUE),
        "url_protocol:", verbatimTextOutput("url_protocol", placeholder = TRUE),
        "url_hostname:", verbatimTextOutput("url_hostname", placeholder = TRUE),
        "url_port:", verbatimTextOutput("url_port", placeholder = TRUE),
        "url_pathname:", verbatimTextOutput("url_pathname", placeholder = TRUE),
        "url_search:", verbatimTextOutput("url_search", placeholder = TRUE),
        "url_hash:", verbatimTextOutput("url_hash", placeholder = TRUE),
        "url_hash_initial:", verbatimTextOutput("url_hash_initial", placeholder = TRUE),
        "(Remaining Items):", verbatimTextOutput("remaining", placeholder = TRUE)
      )
    )
  ),

  shinyjster::shinyjster_js("
    var jst = jster();
    jst.add(Jster.shiny.waitUntilStable);
    jst.add(Jster.shiny.updateHref(window.location.href + '&test=%28fan%C3%A7y%21%29#hashVal'));

    jst.add(function(done) {
      // update the hash value
      window.location = window.location = window.location.href.split('#')[0] + '#updatedHashVal';

      var wait = function() {
        if (
          $('#url_hash').text().trim() !== $('#url_hash_initial').text().trim()
        ) {
          done();
        } else {
          setTimeout(wait, 50);
        }
      }
      wait();
    });

    jst.add(function() {
      function is_equal(id, val) {
        Jster.assert.isEqual(
          $('#' + id).text().trim(),
          val,
          {id: id}
        );
      }

      is_equal('queryText', 'shinyjster=1, test=(fançy!)');

      is_equal('singletons', 'cd08188abc278d3fb2fee5b96fbff85056b59085');

      //// not testing due to inconsistent value
      // is_equal('pixelratio', '2.5');
      // is_equal('url_protocol', 'http');
      // is_equal('url_hostname', '127.0.0.1');
      // is_equal('url_port', '8000');
      // is_equal('url_pathname', '/');

      is_equal('url_search', '?shinyjster=1&test=%28fan%C3%A7y%21%29');
      is_equal('url_hash', '#updatedHashVal');
      is_equal('url_hash_initial', '#hashVal');
    })

    jst.test();
  ")
)

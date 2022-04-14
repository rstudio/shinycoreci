fluidPage(
  HTML("<p>Demonstrates that <code>.R</code> files in the <code>R</code> directory are automatically loaded at runtime.</p>

<p>At the moment, this functionality is opt-in so this app requires setting the following option in order to work:</p>

<pre>
options(shiny.autoload.r = TRUE)
</pre>

<p>Without setting that option, the example will fail.</p>

<p>Requires Shiny with the change in <a href='https://github.com/rstudio/shiny/pull/2547'>https://github.com/rstudio/shiny/pull/2547</a>. This requires Shiny v1.3.2.9001.</p>"),

  counterButton("counter1", "Counter #1"),

  shinyjster::shinyjster_js("
    var jst = jster();
    jst.add(Jster.shiny.waitUntilStable);

    function click() {

      $('#counter1-button').click();
    }

    jst.add(function() {
      Jster.assert.isEqual($('#counter1-out').text().trim(), '0');
    });

    jst.add(function() { Jster.button.click('counter1-button'); });
    jst.add(Jster.shiny.waitUntilStable);
    jst.add(function() { Jster.button.click('counter1-button'); });
    jst.add(Jster.shiny.waitUntilStable);
    jst.add(function() { Jster.button.click('counter1-button'); });
    jst.add(Jster.shiny.waitUntilStable);
    jst.add(function() { Jster.button.click('counter1-button'); });
    jst.add(Jster.shiny.waitUntilStable);

    jst.add(function() {
      Jster.assert.isEqual($('#counter1-out').text().trim(), '4');
    });

    jst.test();
  ")
)

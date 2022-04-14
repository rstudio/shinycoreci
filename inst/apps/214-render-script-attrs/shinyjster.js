var jst = jster();
jst.add(Jster.shiny.waitUntilStable);

jst.add(function() {
  var script = $("head :last-child");
  Jster.assert.isEqual(
    script.attr("src"), "test-1.0.0/test.js"
  );
  Jster.assert.isEqual(
    script.attr("type"), "module"
  );
  Jster.assert.isEqual(
    script.attr("defer"), "defer"
  );
});

jst.test();

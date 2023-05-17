function selectOption(jst, id, index) {
  jst.add(function() {
    Jster.selectize.click(id);
  });
  jst.add(Jster.shiny.waitUntilStable);
  jst.add(function() {
    Jster.selectize.clickOption(id, index);
  });
}

var jst = jster();
jst.add(Jster.shiny.waitUntilStable);

selectOption(jst, "x-col", 1); // choose cyl
selectOption(jst, "y-col", 2); // choose disp

jst.add(Jster.shiny.waitUntilStable);

// renderPlot() should be 1st, plotly 2nd, DT 3rd
var expected_cases = [
  "plot(df_plot)",
  "plot_ly(df_plot, x = ~x, y = ~y) %>% \n   add_markers()",
  "datatable(df_plot)"
];

function expected_script(case_idx) {
    return "dataset <- mtcars \n x_values <- dataset %>% \n   dplyr::pull(!!as.symbol(\"cyl\")) \n y_values <- dataset %>% \n   dplyr::pull(!!as.symbol(\"disp\")) \n # Combine x and y into data frame for plotting \n df_plot <- data.frame(x = x_values, y = y_values) \n " +
    expected_cases[case_idx] +
    " \n x_avg <- x_values %>% \n   mean() %>% \n   round(1) \n paste(\"Average of\", \"cyl\", \"is\", x_avg) \n y_avg <- y_values %>% \n   mean() %>% \n   round(1) \n paste(\"Average of\", \"disp\", \"is\", y_avg)";
}

$("button").each(function(idx) {
  var btn = $(this);
  jst.add(function() {
    btn.click();
  });
  jst.add(Jster.shiny.waitUntilStable);
  jst.add(function() {
    var lines = $(".shiny-ace").data("aceEditor").session.doc.getAllLines();
    Jster.assert.isEqual(
      lines.join(" \n "),
      expected_script(idx)
    );
  });
  jst.add(Jster.shiny.waitUntilStable);
  jst.add(function() {
    $("[data-dismiss='modal']").click();
  });
  jst.add(Jster.shiny.waitUntilStable);
});

jst.test();

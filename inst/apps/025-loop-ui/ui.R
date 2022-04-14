n_letter_groups <- 5
sample_letters <- replicate(n_letter_groups, {list(c("T", "N", "U", "A" ,"X"))})


fluidPage(
  title = 'Creating a UI from a loop',

  sidebarLayout(
    sidebarPanel(
      # create some select inputs
      lapply(1:n_letter_groups, function(i) {
        selectInput(paste0('a', i), paste0('SelectA', i),
                    choices = sample_letters[[i]])
      })
    ),

    mainPanel(
      verbatimTextOutput('a_out'),

      # UI output
      lapply(1:10, function(i) {
        uiOutput(paste0('b', i))
      })
    )
  ),
  shinyjster::shinyjster_js("
    var jst = jster();
    jst.add(Jster.shiny.waitUntilStable);

    jst.add(function() {

      // test verbatim output
      Jster.assert.isEqual(
        $('#a_out').text().trim(),",
        paste0(
          "\"List of ", length(sample_letters), "\\n",
          paste0(collapse = "\\n",
            vapply(seq_along(sample_letters), function(i) {
              paste0(" $ a", i, ": chr \\\"", sample_letters[[i]][1], "\\\"")
            }, character(1))
          ),
          "\""
        ),
      "
      )
      // test b# output
      ",
      vapply(1:10, function(i) {
        paste0( collapse = "\n",
          "Jster.assert.isEqual(\n",
          "  $('#b", 1:10, "').html().trim(),\n",
          "  '<strong>Hi, this is output B#", 1:10, "</strong>'\n",
          ");\n"
        )
      }, character(1))
    ,"});
    jst.test();
  ")
)

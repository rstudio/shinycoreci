### Keep this line to manually test this shiny application. Do not edit this line; shinycoreci::::is_manual_app


library(shiny)

bigvec <- paste0("a", 1:1e5)
named_bigvec <- setNames(bigvec, bigvec)
nested_biglist <- lapply(named_bigvec, function(item) setNames(list(item), item))

test_set <- list(
  "Unnamed vector" = list(
    value = c(1, 2),
    expected = list(
      list(label = "1", value = "1"),
      list(label = "2", value = "2"))),
  "Named vector" = list(
    value = c(a = 1, B = 2),
    expected = list(
      list(label = "a", value = "1"),
      list(label = "B", value = "2"))),
  "Partially named vector" = list(
    value = c(a = 1, B = 2, 3),
    expected = list(
      list(label = "a", value = "1"),
      list(label = "B", value = "2"),
      list(label = "3", value = "3"))),
  "Unnamed list" = list(
    value = list(1, 2),
    expected = list(
      list(label = "1", value = "1"),
      list(label = "2", value = "2"))),
  "Named list" = list(
    value = list(a = 1, B = 2, c = 3),
    expected = list(
      list(label = "a", value = "1"),
      list(label = "B", value = "2"),
      list(label = "c", value = "3"))),
  "Partially named list" = list(
    value = list(a = 1, B = 2, 3),
      expected = list(
      list(label = "a", value = "1"),
      list(label = "B", value = "2"),
      list(label = "3", value = "3"))),
  "Nested list" = list(
    value = list(a = 1, B = list(B = 2), c = list(3)),
    groups = "grouped",
    expected = list(
      list(label = "a", value = "1"),
      list(label = "B", value = "2", group = "B"),
      list(label = "3", value = "3", group = "c"))),
  "Big unnamed vector (server-side only)" = list(
    value = bigvec,
    expected = lapply(1:1000, function(i) {
      list(label = paste0("a", i), value = paste0("a", i))
    })),
  "Big named vector (server-side only)" = list(
    value = named_bigvec,
    expected = lapply(1:1000, function(i) {
      list(label = paste0("a", i), value = paste0("a", i))
    })),
  "Big unnamed list (server-side only)" = list(
    value = as.list(bigvec),
    expected = lapply(1:1000, function(i) {
      list(label = paste0("a", i), value = paste0("a", i))
    })),
  "Big named list (server-side only)" = list(
    value = as.list(named_bigvec),
    expected = lapply(1:1000, function(i) {
      list(label = paste0("a", i), value = paste0("a", i))
    })),
  "Big nested list (server-side only)" = list(
    value = nested_biglist,
    groups = "grouped",
    expected = lapply(1:1000, function(i) {
      list(label = paste0("a", i), value = paste0("a", i), group = paste0("a", i))
    })),
  "Data frame (server-side only)" = list(
    value = data.frame(label = c("a", "B"), value = c(1, 2)),
    expected = list(
      list(label = "a", value = "1"),
      list(label = "B", value = "2")
    ))
)

js_for_id <- function(select_id, output_id, test_val) {
  paste0("
    jst.add(Jster.shiny.waitUntilStable);
    jst.add(function() {
      console.log('", select_id, "');
      console.log('current label')
      Jster.assert.isEqual(
        Jster.selectize.currentOption('", select_id, "'),
        '", test_val$expected[[1]]$label, "'
      );
      Jster.selectize.click('", select_id, "');
    });
    jst.add(Jster.shiny.waitUntilStable);
    jst.add(function() {
      var items = Jster.selectize.values('", select_id, "');
      var expected = ", jsonlite::toJSON(test_val$expected, auto_unbox = TRUE), ";
      console.log('available values')
      Jster.assert.isEqual(items, expected);

      // click
      Jster.selectize.clickOption('", select_id, "', 1); // select second item
    });
    jst.add(Jster.shiny.waitUntilStable);
    jst.add(Jster.shiny.waitUntilStable);
    jst.add(function() {
      console.log('chosen second choice')
      Jster.assert.isEqual(
        $('#", output_id, "').text(),
        '[1] \"", test_val$expected[[2]]$value, "\"',
        {output_id: \"", output_id, "\", obj: $('#", output_id, "')}
      );
    });
  ")
}


is_server_only <- function(test_name) {
  grepl("server-side", test_name)
}



client_output_name <- function(i) paste0("client-", i, "-output")
client_select_name <- function(i) paste0("client-", i, "-select")
server_output_name <- function(i) paste0("server-", i, "-output")
server_select_name <- function(i) paste0("server-", i, "-select")


ui <- fluidPage(
  tags$head(tags$style("
  table, th, td {
    border: 1px solid lightgrey;
    padding: 10px;
  }
  table {
    margin-bottom: 300px;
  }
  ")),
  tags$h1("Selectize with many different types of input values"),
  tags$h4("Validate that only the selectize inputs that state they have groups, have groups"),
  tags$h4("Validate that the clientside (left) and serverside (right) selectize rows behave similarly"),
  tags$table(
    lapply(seq_along(test_set), function(i) {
      test_name <- names(test_set)[i]
      test_val <- test_set[[test_name]]

      group_txt <-
        if (identical(test_val$groups, "grouped"))
          " - HAS GROUPS!"
        else
          ""

      tags$tr(
        tags$td(tags$h5(test_name)),
        tags$td(
          if (is_server_only(test_name)) {
            "- -"
          } else {
            selectizeInput(client_select_name(i), paste0("Client side", group_txt), choices = NULL)
          }
        ),
        tags$td(
          if (is_server_only(test_name)) {
            "- -"
          } else {
            verbatimTextOutput(client_output_name(i))
          }
        ),
        tags$td(
          selectizeInput(server_select_name(i), paste0("Server side", group_txt), choices = NULL)
        ),
        tags$td(
          verbatimTextOutput(server_output_name(i))
        )
      )
    })
  ),
  shinyjster::shinyjster_js(
    "var jst = jster();",
    "jst.add(Jster.shiny.waitUntilStable);",
    paste0(
      collapse = "\n",
      lapply(seq_along(test_set), function(i) {
        test_name <- names(test_set)[i]
        test_val <- test_set[[test_name]]

        paste0(
          if (!is_server_only(test_name))
            js_for_id(client_select_name(i), client_output_name(i), test_val),
          js_for_id(server_select_name(i), server_output_name(i), test_val)
        )
      })
    ),
    "jst.test();"
  )

)

server <- function(input, output, session) {

  # include shinyjster_server call at top of server definition
  shinyjster::shinyjster_server(input, output, session)

  lapply(seq_along(test_set), function(i) {
    test_name <- names(test_set)[i]

    if (!is_server_only(test_name)) {
      updateSelectizeInput(session,
        client_select_name(i),
        choices = test_set[[i]]$value, selected = NULL, server = FALSE
      )

      output[[client_output_name(i)]] <- renderPrint({
        input[[client_select_name(i)]]
      })
    }

    updateSelectizeInput(session,
      server_select_name(i),
      choices = test_set[[i]]$value, selected = NULL, server = TRUE
    )
    output[[server_output_name(i)]] <- renderPrint({
      input[[server_select_name(i)]]
    })
  })

}

shinyApp(ui, server)

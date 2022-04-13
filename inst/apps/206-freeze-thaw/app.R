library(shiny)
library(shinyjster)

# This test app ensures that the different types of Shiny inputs all invalidate
# when updated through either 1) renderUI, or 2) updateXXXInput; and that they
# will invalidate in both of those cases whether the new value is the same or
# different than the existing value.

# This is a list of the different types of inputs in Shiny that have a
# corresponding updateXXXInput function.
defs <- list(
  # The name (text, textarea, ...) is arbitrary, and used to form input IDs for
  # the test.
  text = list(
    # A formula that creates the UI for an input; `.id` and `.value` will be
    # provided at eval time.
    ui = ~textInput(.id, label = NULL, .value),
    # A formula that updates the `.id` input to `.value`.
    update = ~updateTextInput(session, .id, value = .value),
    # A valid value for this input, suitable to be used as `.value` above.
    value1 = "foo",
    # Another value that is not equal to `value1`.
    value2 = "bar"
  ),
  textarea = list(
    ui = ~textAreaInput(.id, label = NULL, .value),
    update = ~updateTextAreaInput(session, .id, value = .value),
    value1 = "a",
    value2 = "b"
  ),
  password = list(
    ui = ~passwordInput(.id, label = NULL, .value),
    update = ~updateTextInput(session, .id, value = .value),
    value1 = "pass1",
    value2 = "pass2pass2"
  ),
  number = list(
    ui = ~numericInput(.id, label = NULL, value = .value),
    update = ~updateNumericInput(session, .id, value = .value),
    value1 = 0,
    value2 = 1
  ),
  checkbox = list(
    ui = ~checkboxInput(.id, label = "yep", value = .value),
    update = ~updateCheckboxInput(session, .id, value = .value),
    value1 = TRUE,
    value2 = FALSE
  ),
  slider = list(
    ui = ~sliderInput(.id, label = NULL, 0, 10, value = .value),
    update = ~updateSliderInput(session, .id, value = .value),
    value1 = 5,
    value2 = 6
  ),
  slider_range = list(
    ui = ~sliderInput(.id, label = NULL, 0, 10, value = .value),
    update = ~updateSliderInput(session, .id, value = .value),
    value1 = c(4, 5),
    value2 = c(5, 6)
  ),
  date = list(
    ui = ~dateInput(.id, label = NULL, value = .value),
    update = ~updateDateInput(session, .id, value = .value),
    value1 = "2020-10-01",
    value2 = "2020-10-04"
  ),
  date_range = list(
    ui = ~dateRangeInput(.id, label = NULL, start = .value[[1]], end = .value[[2]]),
    update = ~updateDateRangeInput(session, .id, start = .value[[1]], end = .value[[2]]),
    value1 = c("2020-10-01", "2020-10-02"),
    value2 = c("2020-10-04", "2020-10-05")
  ),
  selectize = list(
    ui = ~selectInput(.id, label = NULL, letters[1:5], selected = .value),
    update = ~updateSelectInput(session, .id, selected = .value),
    value1 = "a",
    value2 = "b"
  ),
  selectize_multi = list(
    ui = ~selectInput(.id, label = NULL, letters[1:5], selected = .value, multiple = TRUE),
    update = ~updateSelectInput(session, .id, selected = .value),
    value1 = letters[1:2],
    value2 = letters[3:4]
  ),
  select = list(
    ui = ~selectInput(.id, label = NULL, letters[1:5], selected = .value, selectize = FALSE),
    update = ~updateSelectInput(session, .id, selected = .value),
    value1 = "a",
    value2 = "b"
  ),
  select_multi = list(
    ui = ~selectInput(.id, label = NULL, letters[1:5], selected = .value, multiple = TRUE, selectize = FALSE),
    update = ~updateSelectInput(session, .id, selected = .value),
    value1 = letters[1:2],
    value2 = letters[3:4]
  ),
  radio = list(
    ui = ~radioButtons(.id, label = NULL, letters[1:5], selected = .value, inline = TRUE),
    update = ~updateRadioButtons(session, .id, selected = .value),
    value1 = "a",
    value2 = "b"
  ),
  checkbox_group = list(
    ui = ~checkboxGroupInput(.id, label = NULL, letters[1:5], selected = .value, inline = TRUE),
    update = ~updateCheckboxGroupInput(session, .id, selected = .value),
    value1 = letters[1:2],
    value2 = letters[3:4]
  ),
  tabset = list(
    ui = ~do.call(tabsetPanel, c(list(id = .id),
      lapply(letters[1:5], function(x) { tabPanel(x, x) }),
      list(selected = .value))),
    update = ~updateTabsetPanel(session, .id, selected = .value),
    value1 = "b",
    value2 = "c"
  )
)

# An mapply wrapper (I kept forgetting the USE.NAMES and SIMPLIFY options)
apply_defs <- function(fun) {
  mapply(names(defs), defs, FUN = fun, USE.NAMES = FALSE, SIMPLIFY = FALSE)
}

# Given a def$ui, invokes it with the given id and value; returns tag(s)
generate_ui <- function(f, id, value, env = rlang::caller_env()) {
  rlang::eval_tidy(rlang::f_rhs(f), list(.id = id, .value = value), env)
}

ui <- fluidPage(
  fluidRow(
    column(6,
      actionButton("go", "Go"),
      # Outputs whether the test is passing or failing
      verbatimTextOutput("check"),
      helpText("(It's fine for \"Fail\" to appear momentarily)"),
      # Outputs debugging info
      tags$details(
        verbatimTextOutput("debug")
      )
    ),
    column(6,
      # For each definition, create inputs named "NAME_same", and "NAME_diff",
      # and also a uiOutput that will hold "NAME_ui_same" and "NAME_ui_diff".
      apply_defs(function(name, def) {
        tagList(
          h4(name),
          generate_ui(def$ui, id = paste0(name, "_same"), value = def$value1),
          generate_ui(def$ui, id = paste0(name, "_diff"), value = def$value2),
          uiOutput(paste0(name, "_ui_container"))
        )
      })
    )
  ),
  shinyjster_js("
    var jst = jster();
    // Wait for renderUIs to complete
    jst.add(Jster.shiny.waitUntilIdleFor(1000));
    // Cause freeze + update
    jst.add(function() { $('#go').click(); });
    jst.add(Jster.shiny.waitUntilIdleFor(1000));
    // Ensure output$check is OK
    jst.add(function() { Jster.assert.isEqual($('#check').text(), 'OK') });
    jst.test();
  ")
)

# Given the def$update formula `f`, perform a freeze and update.
freeze_and_update_input <- function(f, id, value) {
  session <- getDefaultReactiveDomain()
  freezeReactiveValue(session$input, id)
  rlang::eval_tidy(rlang::f_rhs(f), list(.id = id, .value = value))
}

# Create an observer that counts the number of times `input[[id]]` can
# successfully be read. Maintains a result in `successful_reads[[id]]`.
count_obs <- function(id, successful_reads) {
  session <- getDefaultReactiveDomain()
  force(id)

  successful_reads[[id]] <- 0

  observe({
    # Nulls need to be explicitly excluded so we don't count the time before
    # renderUI-based inputs are initialized.
    #
    # Note also that if `input[[id]]` is frozen, the count won't be incremented.
    req(!is.null(session$input[[id]]))

    successful_reads[[id]] <- successful_reads[[id]] + 1
  })
}

server <- function(input, output, session) {
  shinyjster::shinyjster_server(input, output, session)

  # Maintains the number of times each input is read
  successful_reads <- new.env(parent = emptyenv())

  # For each definition...
  apply_defs(function(name, def) {

    first_time <- TRUE

    # Render the NAME_ui_[same|diff] inputs
    output[[paste0(name, "_ui_container")]] <- renderUI({
      # Rerender whenever `input$go` is clicked
      input$go

      # The value to use for NAME_ui_diff depends on whether this is the first
      # time we're ever rendering or not. The point is to get the first click
      # of `input$go` to cause a `renderUI` that changes the value. (As opposed
      # to NAME_ui_same, that always defaults to the same value no matter what.)
      diff_value <- if (first_time) def$value2 else def$value1
      first_time <<- FALSE

      # Freeze and render
      freezeReactiveValue(input, paste0(name, "_ui_same"))
      freezeReactiveValue(input, paste0(name, "_ui_diff"))
      tagList(
        generate_ui(def$ui, paste0(name, "_ui_same"), def$value1),
        generate_ui(def$ui, paste0(name, "_ui_diff"), diff_value)
      )
    })

    # For the non-renderUI inputs, we just freeze and updateXXXInput whenever
    # the button is clicked.
    observeEvent(input$go, {
      freeze_and_update_input(def$update, paste0(name, "_same"), def$value1)
      freeze_and_update_input(def$update, paste0(name, "_diff"), def$value1)
    }, priority = -1)

    # Count observations for all of the inputs we create.
    count_obs(paste0(name, "_same"), successful_reads)
    count_obs(paste0(name, "_diff"), successful_reads)
    count_obs(paste0(name, "_ui_same"), successful_reads)
    count_obs(paste0(name, "_ui_diff"), successful_reads)
  })

  output$check <- renderPrint({
    # Re-check every time any input changes
    reactiveValuesToList(input)

    # We expect every input element to have been successfully read upon startup,
    # and once per click of the go button
    if (all(input$go + 1 == unlist(as.list(successful_reads)))) {
      cat("OK\n")
    } else {
      cat("Fail\n")
    }
  })
  # Make sure not to run the check until all of the count_obs have completed
  outputOptions(output, "check", priority = -10)

  # Print all the successful_reads counts
  output$debug <- renderPrint({
    reactiveValuesToList(input)

    df <- data.frame(reads = unlist(as.list(successful_reads)))
    # Order by reads and then rownames, so it's more obvious when the values are
    # not all the same
    df <- df[order(df$reads, rownames(df)),,drop = FALSE]
    print(df)
  })
  outputOptions(output, "debug", priority = -10)
}

shinyApp(ui, server)

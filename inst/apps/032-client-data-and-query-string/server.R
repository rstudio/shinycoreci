list_to_string <- function(obj, listname) {
  if (is.null(names(obj))) {
    paste(listname, "[[", seq_along(obj), "]] = ", obj,
          sep = "", collapse = "\n")
  } else {
    paste(listname, "$", names(obj), " = ", obj,
          sep = "", collapse = "\n")
  }
}

function(input, output, session) {

  shinyjster::shinyjster_server(input, output, session)

  known_names <- c(
    "output_queryText_hidden",
    "url_search",
    "url_protocol",
    "url_port",
    "url_hash_initial",
    "singletons",
    "output_summary_hidden",
    "url_pathname",
    "url_hash",
    "url_hostname",
    "pixelratio"
  )
  # set table values of known items
  lapply(known_names, function(name) {
    output[[name]] <- renderText({
      val <- session$clientData[[name]]
      if (is.list(val)) {
        list_to_string(val, name)
      } else {
        # Special case for shinytest: set url_port to a fixed value because it
        # is randomly generated.
        if (isTRUE(getOption("shiny.testmode")) && name == "url_port") {
          val <- 99999
        }
        as.character(val)
      }
    })
  })

  # Print out the remaining clientData, which is a reactiveValues object.
  # This object is list-like, but it is not a list.
  output$remaining <- renderText({
    # Find the names of all the keys in clientData
    cnames <- names(session$clientData)
    cnames <- setdiff(cnames, known_names)

    # Apply a function to all keys, to get corresponding values
    allvalues <- lapply(cnames, function(name) {
      item <- session$clientData[[name]]
      if (is.list(item)) {
        list_to_string(item, name)
      } else {
        paste(name, item, sep=" = ")
      }
    })
    paste(allvalues, collapse = "\n")
  })

  # Parse the GET query string
  output$queryText <- renderText({
    query <- parseQueryString(session$clientData$url_search)

    # Return a string with key-value pairs
    paste(names(query), query, sep = "=", collapse=", ")
  })

}

# Test app for https://github.com/rstudio/shiny/pull/3666

library(later)
library(promises)
library(httpuv)
library(htmltools)
library(shiny)
# options(shiny.minified = FALSE)

# ==============================================================================
# Monkey-patch shiny::uiHttpHandler so that UI functions can return a promise.
# ==============================================================================

# This function recurses into `expr`, looking for `search_expr`. If it finds
# it, it will return `replace_expr`. Notably, `replace_expr` can contain rlang
# operators like `!!`, and perform rlang substitution on them.
monkey_patch <- function(
  expr,
  search_expr,
  replace_expr
) {
  if (typeof(expr) != "language") {
    stop("monkey_patch only works on language objects (AKA quoted expressions)!")
  }

  # Look for search_expr in the code. If it matches, return replace_expr, but do
  # substitution on it.
  if (identical(
    removeSource(search_expr),
    removeSource(expr[seq_along(search_expr)])
  )) {
    result <- rlang::inject(rlang::expr(!!replace_expr))
    return(result)
  }

  # If we get here, then expr is a language object, but not the one we were
  # looking for. Recurse into it. We would use lapply here if we could, but that
  # returns a list instead of language object. So we'll iterate using a for loop
  # instead.
  for (i in seq_along(expr)) {
    # Recurse only if expr[[i]] is a language object.
    if (typeof(expr[[i]]) == "language") {
      expr[[i]] <- monkey_patch(expr[[i]], search_expr, replace_expr)
    }
  }

  expr
}

# This searches for the following in a shiny:::uiHttpHandler:
#   if (inherits(uiValue, "httpResponse")) { return(uiValue) } ...
# When it finds it, it will make it an `else` condition of the following:
#   if (is.promise(uiValue)) { return(uiValue) }
#   else xxxx
# It modifies the body of the shiny:::uiHttpHandler function. This function
# also will only modify shiny:::uiHttpHandler one time.
add_promise_shiny_uiHttpHandler <- function() {
  if (exists(".shiny_uiHttpHandler_updated", .GlobalEnv)) {
    return()
  }

  shiny_uiHttpHandler <- shiny:::uiHttpHandler
  fn_body <- body(shiny_uiHttpHandler)
  fn_body <- monkey_patch(
    fn_body,
    quote(
      if (inherits(uiValue, "httpResponse")) { return(uiValue) }
    ),
    quote(
      if (is.promise(uiValue)) { return(uiValue) } else !!expr
    )
  )

  body(shiny_uiHttpHandler) <- fn_body
  assignInNamespace("uiHttpHandler", shiny_uiHttpHandler, "shiny")

  .GlobalEnv$.shiny_uiHttpHandler_updated <- TRUE
}

add_promise_shiny_uiHttpHandler()

# ==============================================================================
# App
# ==============================================================================
ui <- function(req) {
  path <- req$PATH_INFO
  message("Request received for ", path)

  # Request is for main HTML page
  if (path == "/") {
    return(
      fluidPage(
        fluidRow(
          h2("Dynamic <script> loading test"),

          radioButtons("type", "Test type",
            c("None" = "none", "Delay 2s" = "delay", "Error" = "error")
          ),
          uiOutput("content"),
          pre(id = "dyn-content"),
          markdown(
            "
This app tests the loading order of \\<script> tags in HTML dependencies, for
[PR #3666](https://github.com/rstudio/shiny/pull/3666).
The starting state is **none**, which means to not load any script tags.

*****

When **delay** is selected, it will try to load the following scripts:
* a-1.js
* a-2-delay.js: This will load with 2 second delay.
* a-3-404.js: The server will respond with a 404.
* a-4.js
* b-1.js

Even though the client should download a-4.js _before_ a-2-delay.js, they should
still be executed in the order in which they're inserted in the DOM. These will
be logged to the code block, and should be in this order:
* a-1.js
* a-2-delay.js
* a-4.js
* b-1.js

(a-3-404.js won't execute because the server replies with a 404.)

*****

When **error** is selected, it will try to load the following scripts:
* a-1.js
* a-2-error.js: This script will throw an error.
* a-3-404.js: The server will respond with a 404.
* a-4.js
* b-1.js

The scripts should log the following to the code block:
* a-1.js
* a-4.js
* b-1.js

a-2-error.js will execute, but it will throw an error before it logs to the code
block. a-3-404.js won't execute because the server response is a 404. Note that
despite the JS error and the missing file, it should continue running subsequent
scripts: a-4.js and b-1.js.
           "
          ),
          div("Shiny version ", as.character(packageVersion("shiny"))),
        ),
        shinyjster::shinyjster_js("
          var jst = jster();

          // Test 'delay' button
          jst.add(function() {
            Jster.radio.clickOption('type', 'delay');
          });
          jst.add(function(done) { setTimeout(done, 2500); });
          jst.add(Jster.shiny.waitUntilIdle);
          jst.add(function() {
            Jster.assert.isEqual(
              $('#dyn-content').text().trim(),
              [
                'Ran /test/a-1.js',
                'Ran /test/a-2-delay.js',
                'Ran /test/a-4.js',
                'Ran /test/b-1.js'
              ].join('\\n')
            );
          })

          // Test 'error' button
          jst.add(function() {
            Jster.radio.clickOption('type', 'error');
          });
          jst.add(function(done) { setTimeout(done, 500); });
          jst.add(Jster.shiny.waitUntilIdle);
          jst.add(function() {
            Jster.assert.isEqual(
              $('#dyn-content').text().trim(),
              [
                'Ran /test/a-1.js',
                'Ran /test/a-2-delay.js',
                'Ran /test/a-4.js',
                'Ran /test/b-1.js',
                'Ran /test/a-1.js',
                'Ran /test/a-4.js',
                'Ran /test/b-1.js',
              ].join('\\n')
            );
          })

          jst.test();
        ")
      )
    )
  }

  # Request is for one of our custom JS files
  if (grepl("^/test/.*\\.js", path)) {

    # If the requested name contains "404", then send a 404 response.
    if (grepl("^/test/.*404", path)) {
      return(
        structure(
          list(status = 404, content = "Not found"),
          class = "httpResponse"
        )
      )
    }

    # Fill in the content for a response containing a JS file.
    body <- ""

    if (grepl("error", path)) {
      body <- paste0(body, "throw 'An error happened in ", path, "';\n")
    }
    body <- paste0(
      body,
      sprintf(
        "
        (() => {
          const msg = 'Ran %s\\n';
          console.log(msg);
          const d = document.getElementById('dyn-content');
          if (d) {
            d.innerHTML += msg;
          }
        })();
        ",
        path
      )
    )

    res <- structure(
      list(
        status = 200L,
        headers = list('Content-Type' = 'text/javascript'),
        content = body
      ),
      class = "httpResponse"
    )


    if (grepl("delay", path)) {
      return(
        promise(function(resolve, reject) {
          message("Promise for ", path)

          message("Delaying for ", path)
          later::later(
            function() {
              message("Resolving", path)
              resolve(res)
            },
            2
          )
        })
      )
    } else {
      return(res)
    }
  }

  # Request is for something else (normal static assets). Fall through.
  NULL
}


shinyApp(
  ui = ui,
  server = function(input, output, session) {
    shinyjster::shinyjster_server(input, output, session)

    output$content <- renderUI({
      if (input$type == "none") {
        return(div())
      } else if (input$type == "delay") {
        type <- "delay"
      } else if (input$type == "error") {
        type <- "error"
      }

      div(
        htmlDependency(
          paste0("test-", type, "-a"),
          "1.0",
          src = list(href = "/test"),
          script = c(
            "a-1.js",
            paste0("a-2-", type, ".js"),
            "a-3-404.js",
            "a-4.js"
          )
        ),
        htmlDependency(
          paste0("test-", type, "-b"),
          "1.0",
          src = list(href = "/test"),
          script = "b-1.js"
        )
      )
    })
  },
  uiPattern = "^/|(/test).*"
)

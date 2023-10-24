library(bslib)
library(shiny)

print(getwd())
png_dt <- jsonlite::unserializeJSON(paste0(readLines("data.json"), collapse = "\n"))

ui <- bslib::page_sidebar(
  shiny::uiOutput("title"),
  "Diff: ", shiny::verbatimTextOutput("diff_count"),
  shiny::imageOutput("diff_image"),
  sidebar = bslib::sidebar(
    style="white-space: nowrap;",
    Map(
      seq_len(nrow(png_dt)),
      png_dt$app,
      png_dt$snap,
      png_dt$platform_combo,
      f = function(i, app, snap, platform_combo) {
        shiny::actionLink(
          paste0("link_", i),
          # paste0(app, " ", snap, " on ", platform_combo)
          paste0(app, "/", platform_combo, "/", snap)
        )
      }
    )
  )
)

server <- function(input, output, session) {
  bad_row <- reactiveVal(1)

  lapply(seq_len(nrow(png_dt)), function(i) {
    diff_image <- png_dt$diff_file[i]

    observe({
      req(input[[paste0("link_", i)]]) # Force reactivity
      bad_row(i)
    })
  })

  output$title <- shiny::renderUI({
    req(bad_row())
    info <- as.list(png_dt[bad_row(), ])
    shiny::tagList(
      shiny::h1(
        shiny::a(
          target="_blank",
          href=paste0("https://github.com/rstudio/shinycoreci/tree/main/inst/apps/", info$app),
          info$app
        )
      ),
      shiny::p(
        "Snap: ",
        shiny::a(
          target="_blank",
          href=paste0("https://github.com/rstudio/shinycoreci/tree/main/", info$file),
          paste0(tail(strsplit(info$file, "/")[[1]], 3), collapse = "/")
        )
      ),
      shiny::p(
        "App: ",
        shiny::a(
          target="_blank",
          href=paste0("https://testing-apps.shinyapps.io/", info$app),
          "shinyapps.io"
        )
      ),

      shiny::p(
        "Diff: ",
        shiny::code(info$diff_count)
      ),
    )
  })

  output$diff_image <- shiny::renderImage({
    req(bad_row())
    list(
      src = file.path("image_diffs", basename(png_dt$diff_file[bad_row()])),
      contentType = "image/png",
      width = "100%",
      style="border: 1px solid black;"
    )
  }, deleteFile = FALSE)
}

shiny::shinyApp(ui, server)

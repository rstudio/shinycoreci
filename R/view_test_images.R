#' View Shinytest Images
#'
#' @param dir path pointing to shinycoreci-apps/apps
#' @export
view_test_images <- function(dir = "apps") {
  dir <- normalizePath(dir, mustWork = TRUE)
  all_files <- dir(dir, recursive = TRUE, full.names = TRUE)
  all_pngs <- grep(
    paste0("^", file.path(dir, ".*", "tests", "shinytest", ".*", ".*\\.png"), "$"),
    all_files, value = TRUE
  )
  m <- regexec(file.path(dir, "(.*)", "tests"), all_pngs)
  all_png_app_names <- vapply(regmatches(all_pngs, m), function(x) x[2], character(1))

  ui <- shiny::fluidPage(
    shiny::wellPanel(
      shiny::selectInput("app_name", "Choose a testing app", unique(all_png_app_names))
    ),
    shiny::uiOutput("images")
  )

  server <- function(input, output, session) {
    app_png_idx <- shiny::reactive({
      req(input$app_name)
      grep(input$app_name, all_pngs)
    })
    app_pngs <- shiny::reactive(all_pngs[app_png_idx()])
    app_test_names <- shiny::reactive(all_png_test_names[app_png_idx()])

    shiny::observe({
      lapply(app_pngs(), function(x) {
        output[[x]] <- shiny::renderImage({
          list(src = x, width = "100%")
        }, deleteFile = FALSE)
      })
    })
    output$images <- shiny::renderUI({
      png_names <- app_pngs()
      row_names <- unique(basename(png_names))
      row_tags <- lapply(row_names, function(row) {
        row_pngs <- png_names[basename(png_names) %in% row]
        row_images <- lapply(row_pngs, function(png) {
          test_name <- basename(dirname(png))
          # Remove the shinytest test name as it's not very informative
          test_name <- paste(strsplit(test_name, "-")[[1]][-1], collapse = "-")
          img_tag <- shiny::div(
            shiny::tags$p(test_name),
            shiny::imageOutput(png)
          )
          shiny::column(
            max(4, round(12 / length(row_pngs))),
            img_tag
          )
        })
        shiny::wellPanel(
          shiny::h3(paste("Screenshot", english::english(match(row, row_names)))),
          shiny::br(), shiny::fluidRow(!!!row_images)
        )
      })
    })
  }

  shiny::shinyApp(ui, server)
}




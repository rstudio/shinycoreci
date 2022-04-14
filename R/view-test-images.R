#' View Shinytest Images
#'
#' @param repo_dir directory to the shinycoreci repo
#' @export
view_test_images <- function(repo_dir = ".") {
  repo_dir <- normalizePath(repo_dir, mustWork = TRUE)
  apps_folder <- file.path(repo_dir, "inst/apps")

  all_files <- dir(apps_folder, recursive = TRUE, full.names = TRUE)

  # Only keep snapshot files
  all_files <- all_files[grepl("tests/testthat/_snaps/", all_files)]
  # Only png files
  # No debug snapshots
  all_pngs <- all_files[grepl("[^_]\\.png", all_files)]
  # Not new png files
  all_pngs <- all_pngs[!grepl("\\.new\\.png", all_pngs)]

  m <- regexec(file.path(apps_folder, "(.*)", "tests"), all_pngs)
  all_png_app_names <- vapply(regmatches(all_pngs, m), function(x) x[2], character(1))

  ui <- shiny::fluidPage(
    shiny::wellPanel(
      shiny::selectInput("app_name", "Choose a testing app", unique(all_png_app_names))
    ),
    shiny::uiOutput("images")
  )

  server <- function(input, output, session) {
    app_png_idx <- shiny::reactive({
      shiny::req(input$app_name)
      grep(input$app_name, all_pngs)
    })
    app_pngs <- shiny::reactive(all_pngs[app_png_idx()])

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
          test_name <- sub("-expected", "", test_name)
          img_tag <- shiny::div(
            shiny::tags$p(test_name),
            shiny::imageOutput(png, height = "auto")
          )
          shiny::column(
            max(3, round(12 / length(row_pngs))),
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

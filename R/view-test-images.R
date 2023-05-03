#' View Shinytest Images
#'
#' @param repo_dir directory to the shinycoreci repo
#' @export
view_test_images <- function(repo_dir = ".") {
  app_folders <- Filter(repo_apps_paths(repo_dir), f = function(app_folder) {
    dir.exists(file.path(app_folder, "tests/testthat/_snaps"))
  })

  png_dt <-
    dplyr::bind_rows(lapply(app_folders, function(app_folder) {
      app_files <- dir(app_folder, recursive = TRUE, full.names = TRUE)

      # Only png files
      app_pngs <- app_files[grepl("\\.png$", app_files)]
      # No debug snapshots
      # Not new png files
      app_pngs <- app_pngs[!grepl("(_|\\.new)\\.png$", app_pngs)]

      test_name = dirname(app_pngs)
      variant = dirname(test_name)

      dplyr::tibble(
        app_name = basename(app_folder),
        variant = basename(variant),
        png_name = basename(app_pngs),
        test_name = basename(test_name),
        path = app_pngs
      )
    }))

  ui <- shiny::fluidPage(
    shiny::wellPanel(
      shiny::selectInput("app_name", "Choose a testing app", unique(png_dt$app_name))
    ),
    shiny::uiOutput("images")
  )

  server <- function(input, output, session) {
    app_png_idx <- shiny::reactive({
      shiny::req(input$app_name)
      input$app_name == png_dt$app_name
    })
    app_png_info <- shiny::reactive(png_dt[app_png_idx(), ])
    app_pngs <- shiny::reactive(app_png_info()$path)

    shiny::observe({
      lapply(app_pngs(), function(x) {
        output[[x]] <- shiny::renderImage({
          list(src = x, width = "100%")
        }, deleteFile = FALSE)
      })
    })
    output$images <- shiny::renderUI({
      app_png_dt <- app_png_info()
      test_names <- unique(app_png_dt[, c("png_name", "test_name")])
      images <- Map(
        test_names$png_name,
        test_names$test_name,
        f = function(png_name_, test_name_) {
          test_dt <- dplyr::filter(app_png_dt, png_name == png_name_, test_name == test_name_)
          # row_pngs <- png_names[basename(png_names) %in% row]
          row_images <-
            Map(
              test_dt$variant,
              test_dt$path,
              f = function(variant, png_path) {
                shiny::column(
                  max(3, round(12 / nrow(test_dt))),
                  shiny::div(
                    shiny::tags$p(paste0(variant, "/", test_name_)),
                    shiny::imageOutput(png_path, height = "auto")
                  )
                )
              }
            )
          row_images <- unname(row_images)
          shiny::wellPanel(
            shiny::h3(paste("Screenshot", png_name_)),
            shiny::br(), shiny::fluidRow(!!!row_images)
          )
        }
      )
      unname(images)
    })
  }

  shiny::shinyApp(ui, server)
}

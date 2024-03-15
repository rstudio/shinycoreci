utils::globalVariables(c("png_name", "test_name", "variant"))

#' View Shinytest Images
#'
#' @param repo_dir directory to the shinycoreci repo
#' @export
view_test_images <- function(repo_dir = rprojroot::find_package_root_file()) {
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
      # Has _snaps folder
      app_pngs <- app_pngs[grepl("/_snaps/", app_pngs)]

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
          test_dt <- dplyr::arrange(test_dt, variant)
          platform_and_version <- strsplit(test_dt$variant, "-")
          test_dt$platform <- sapply(platform_and_version, "[", 1)
          test_dt$r_version <- sapply(platform_and_version, "[", 2)

          rows <-
            lapply(unique(test_dt$platform), function(platform_) {
              p_dt <- dplyr::filter(test_dt, platform == platform_)
              row_images <-
                Map(
                  p_dt$variant,
                  p_dt$path,
                  f = function(variant, png_path) {
                    shiny::div(
                      style="padding-right: 5px;",
                      shiny::tags$p(variant, style="margin-bottom: 5px;margin-top: 5px;"),
                      shiny::imageOutput(png_path, height = "auto", width = "100%")
                    )
                  }
                )
              row_images <- unname(row_images)
              shiny::div(
                style="display: flex;",
                !!!row_images
              )
            })
          shiny::wellPanel(
            shiny::h3(paste("Screenshot:", paste0(test_name_, "/", png_name_)), style="margin-top:0"),
            # shiny::br(),
            rows
          )
        }
      )
      unname(images)
    })
  }

  shiny::shinyApp(ui, server)
}


run_app <- function(
  app_dir,
  host,
  port
) {
  if ("index.Rmd" %in% dir(app_dir)) {
    rmarkdown::run(
      file.path(app_dir, "index.Rmd"),
      shiny_args = list(
        port = port,
        host = host
      )
    )
  } else {
    shiny::runApp(
      app_dir,
      port = port,
      host = host
    )
  }

}


run_app <- function(
  app_dir,
  host,
  port
) {
  if ("index.Rmd" %in% dir(app)) {
    rmarkdown::run(
      file.path(app, "index.Rmd"),
      shiny_args = list(
        port = port,
        host = host
      )
    )
  } else {
    shiny::runApp(
      app,
      port = port,
      host = host
    )
  }

}

resolve_app_name <- function(app, known_apps = NULL) {
  if (is.null(app)) return(NULL)
  if (length(app) > 1) {
    return(
      vapply(app, resolve_app_name, character(1))
    )
  }
  if (!is.null(known_apps)) {
    app_names <- known_apps
    app_num_map <- get_app_num_map(app_names)
    app_name_map <- get_app_name_map(app_names)
  }
  resolved_app <-
    if (is.numeric(app)) {
      app_num_map[[as.character(app)]]
    } else if (is.character(app)) {
      if (app %in% app_names) {
        app
      } else {
        app_name_map[[app]]
      }
    } else {
      stop("`app` must be a character or numeric")
    }

  if (! isTRUE(resolved_app %in% app_names)) {
    stop("`app` must be a valid app name. Received: ", app)
  }

  resolved_app
}
next_app_name <- function(app, manual = TRUE) {
  if (is.null(app)) return(NULL)
  resolved_app <- resolve_app_name(app)
  apps <- if (manual) apps_manual else app_names
  pos <- which(apps == resolved_app)
  if (pos == length(apps)) {
    return(NULL)
  }
  apps[pos + 1]
}


app_has_shinyjster <- function(app_name) {
  app_has_test_file(app_name, "shinyjster")
}

app_has_test_file <- function(app_name, test_file_regex) {
  app_path_val <- app_path(app_name)
  files <- dir(file.path(app_path_val, "tests", "testthat"))

  any(grepl(test_file_regex, files))
}



app_path <- function(app_name) {
  app_name <- resolve_app_name(app_name)
  app_path_val <- file.path(apps_folder, app_name)
  app_path_val
}


# This function MUST be simple and not contain any other helper methods (ex: `app_path()`)
run_app <- function(app_name, ..., is_dev = FALSE, apps_folder = system.file("apps", package = "shinycoreci")) {
  # Load local path for apps to be found
  app_path <-
    if (isTRUE(is_dev)) {
      load_all <- get("load_all", envir = asNamespace("pkgload"))
      message("calling pkgload::load_all()")
      load_all()
      pkg_path <- system.file(package = "shinycoreci")
      if ("inst" %in% dir(pkg_path)) {
        pkg_path <- file.path(pkg_path, "inst")
      }
      file.path(pkg_path, "apps", app_name)
    } else {
      file.path(apps_folder, app_name)
    }

  if (! file.exists(app_path)) {
    stop("App not found: ", app_path)
  }

  if ("index.Rmd" %in% dir(app_path)) {
    rmarkdown::run(
      file.path(app_path, "index.Rmd"),
      shiny_args = list(...)
    )
  } else {
    shiny::runApp(app_path, ...)
  }
}

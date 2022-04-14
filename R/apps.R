
shiny_app_files <- function(app_folder) {
  dir(app_folder, pattern = "^(app|ui|server)\\.(r|R)$", full.names = TRUE)
}
has_shiny_app_files <- function(app_folder) {
  length(shiny_app_files(app_folder) > 0)
}
rmarkdown_app_files <- function(app_folder) {
  dir(app_folder, pattern = "^index\\.(Rmd|rmd)$", full.names = TRUE)
}
has_rmarkdown_app_files <- function(app_folder) {
  length(rmarkdown_app_files(app_folder) > 0)
}
has_shinyish_files <- function(app_folder) {
  has_shiny_app_files(app_folder) || has_rmarkdown_app_files(app_folder)
}
has_tests_folder <- function(app_folder) {
  "tests" %in% dir(app_folder)
}



# Flag must be at the end of the line
manual_app_info <- list(
  string = "### Keep this line to manually test this shiny application. Do not edit this line; shinycoreci::::is_manual_app",
  flag = "shinycoreci::::is_manual_app"
)

is_manual_app <- function(app_dir) {
  app_or_ui_files <- c(shiny_app_files(app_dir), rmarkdown_app_files(app_dir))

  flag <- manual_app_info$flag
  for (app_file in app_or_ui_files) {
    if (
      any(grepl(
        # if the flag appears in the file... success!
        flag,
        readLines(app_file, n = 100)
      ))
    ) {
      return(TRUE)
    }
  }
  FALSE
}


### Start GHA
apps_with_tests <- function(repo_dir = ".") {
  basename(Filter(x = repo_apps_paths(repo_dir), has_tests_folder))
}
repo_apps_path <- function(repo_dir = ".") {
  file.path(repo_dir, "inst", "apps")
}
repo_apps_paths <- function(repo_dir = ".") {
  dir(repo_apps_path(repo_dir), pattern = "^\\d\\d\\d-", full.names = TRUE)
}
repo_app_path <- function(app_name, repo_dir = ".") {
  file.path(repo_apps_path(repo_dir), app_name)
}

### End GHA



## _Package Globals_
apps_folder <- app_names <- app_nums <- app_name_map <- app_num_map <- NULL
app_paths <- app_paths_map <- NULL
apps_manual <- apps_shiny <- NULL


get_app_nums <- function(app_names) {
  as.numeric(vapply(strsplit(app_names, "-"), `[[`, character(1), 1))
}
get_app_name_map <- function(app_names) {
  setNames(as.list(app_names), app_names)
}
get_app_num_map <- function(app_names) {
  setNames(as.list(app_names), as.character(get_app_nums(app_names)))
}

apps_on_load <- function() {
  apps_folder <<- system.file(package = "shinycoreci", "apps")
  app_names <<- dir(apps_folder)
  app_names <<- grep("^\\d\\d\\d-", app_names, value = TRUE)
  app_nums <<- get_app_nums(app_names)
  app_name_map <<- get_app_name_map(app_names)
  app_num_map <<- get_app_num_map(app_names)

  app_paths <<- file.path(apps_folder, app_names)
  app_path_map <<- setNames(as.list(app_paths), app_names)

  apps_manual <<- basename(Filter(x = app_paths, is_manual_app))
  apps_shiny  <<- basename(Filter(x = app_paths, has_shinyish_files))
}

shinyverse_pkgs <- function() {
  ## Don't install apps_deps here. Let the methods install them if they're missing
  paste0(
    c(
      # Minimum required packages to perform testing
      "shiny", "shinytest2",
      NULL
    ),
    collapse = ","
  )
}

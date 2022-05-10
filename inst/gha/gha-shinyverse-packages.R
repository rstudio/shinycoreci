# Set an output variable for GHA to use in installations

shinyverse_remotes_file <- "R/data-shinyverse-remotes.R"
stopifnot(file.exists(shinyverse_remotes_file))

apps_deps_file <- "R/data-apps_deps.R"
stopifnot(file.exists(apps_deps_file))

source(shinyverse_remotes_file)
stopifnot(length(shinyverse_remotes) > 0)

source(apps_deps_file)
stopifnot(length(apps_deps) > 0)

# Very difficult to have both urls and remotes mixed. Does not really work in practice
# Ex:
# Error: Cannot install packages:
# * url::https://github.com/rstudio/shinytest2/archive/HEAD.zip:
#   * Can't install dependency rstudio/shiny
#   * Can't install dependency rstudio/shinyvalidate
# * rstudio/shinyvalidate: Conflicts with url::https://github.com/rstudio/shinyvalidate/archive/HEAD.zip
# * rstudio/shiny: Conflicts with url::https://github.com/rstudio/shiny/archive/HEAD.zip

# # Use URL type to download shinyverse.
# # Speed is not as important as minimizing GHA requests
# pak_shinyverse_urls <- paste0(
#   # url::https://github.com/tidyverse/stringr/archive/HEAD.zip
#   # "url::https://github.com/", shinyverse_remotes, "/archive/HEAD.zip"
#   shinyverse_remotes
# )

cat(
  "::set-output name=packages::",
  paste0(
    c(
      shinyverse_remotes,
      paste0("any::", apps_deps)
    ),
    collapse = ","
  ),
  "\n",
  sep = ""
)

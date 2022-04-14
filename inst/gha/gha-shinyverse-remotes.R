# Set an output variable for GHA to use in installations

shinyverse_remotes_file <- "R/data-shinyverse-remotes.R"
stopifnot(file.exists(shinyverse_remotes_file))

source(shinyverse_remotes_file)
stopifnot(length(shinyverse_remotes) > 0)

# Use URL type to download shinyverse.
# Speed is not as important as minimizing GHA requests
pak_shinyverse_urls <- paste0(
  # url::https://github.com/tidyverse/stringr/archive/HEAD.zip
  "url::https://github.com/", shinyverse_remotes, "/archive/HEAD.zip"
  # shinyverse_remotes
)

cat(
  "::set-output name=remotes::",
  paste0(pak_shinyverse_urls, collapse = ","),
  "\n",
  sep = ""
)

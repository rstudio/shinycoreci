# Set an output variable for GHA to use in installations

shinyverse_remotes_file <- "R/data-shinyverse-remotes.R"
stopifnot(file.exists(shinyverse_remotes_file))

source(shinyverse_remotes_file)
stopifnot(length(shinyverse_remotes) > 0)

cat(
  "::set-output name=remotes::",
  paste0(shinyverse_remotes, collapse = ","),
  "\n",
  sep = ""
)

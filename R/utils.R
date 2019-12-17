

# Remove files, but only try to remove if they exist (so we don't get
# warnings).
rm_files <- function(filenames) {
  # Only try to remove files that actually exist
  filenames <- filenames[file.exists(filenames)]
  file.remove(filenames)
}

# add a few lines that requires shiny, but will never be used
local({
  run_app <- function(...) {
    shiny::runApp(...)
  }
})

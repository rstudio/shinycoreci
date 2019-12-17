

# Remove files, but only try to remove if they exist (so we don't get
# warnings).
rm_files <- function(filenames) {
  # Only try to remove files that actually exist
  filenames <- filenames[file.exists(filenames)]
  file.remove(filenames)
}

# What is being tested is if shiny is capturing all of the dynamic inputs/outputs
# 191-reactlog-pythagoras tests on all platforms and r versions, so that functionality is covered

# Only run these tests on mac + r-release

# (To reduce the amount of screenshot diffing noise)
release <- rversions::r_release()$version
release <- paste0(
  strsplit(release, ".", fixed = TRUE)[[1]][1:2],
  collapse = "."
)
if (identical(paste0("mac-", release), shinytest2::platform_variant())) {

  # Yell if there are extra expected folders
  folders <- dir("shinytest", pattern = "-expected-")
  is_bad_folder <- !(grepl(paste0("-", release, "$"), folders) & grepl("-mac-", folders))
  if (any(is_bad_folder)) {
    stop("Unexpected output folders found:\n", paste0("* ", folders[is_bad_folder], collapse = "\n"))
  }

  shinytest2::test_app()
}

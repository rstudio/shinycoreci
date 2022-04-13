library(shinytest)
library(bslib)

# Only run these tests on mac + r-release
# (To reduce the amount of screenshot diffing noise)
release <- rversions::r_release()$version
release <- paste0(
  strsplit(release, ".", fixed = TRUE)[[1]][1:2],
  collapse = "."
)
if (identical(paste0("mac-", release), shinytest2::platform_variant())) {
  # Yell if there are extra expected folders
  folders <- dir("testthat/_snaps")
  is_bad_folder <- folders != paste0("mac-", release)
  if (any(is_bad_folder)) {
    stop("Unexpected output folders found:\n", paste0("* ", folders[is_bad_folder], collapse = "\n"))
  }

  shinytest2::test_app()
}

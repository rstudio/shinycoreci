# Check if ~/.Rprofile exists and source it
if (file.exists(normalizePath("~/.Rprofile"))) {
  source(normalizePath("~/.Rprofile"))
}

# Allow for a 10% difference in the screenshot kernel
# (3x RGB channels * kernel_size^2) * 10% = threshold
options(
  shinytest2.compare_screenshot.kernel_size = 50,
  shinytest2.compare_screenshot.threshold = 50^2 * 3 * 0.1
)

# Check if ~/.Rprofile exists and source it
if (file.exists(normalizePath("~/.Rprofile"))) {
  source(normalizePath("~/.Rprofile"))
}

# Allow for a 10% difference in the screenshot kernel
# 187.5 / (3x RGB channels * 25 * 25) = 187.5 / 1875 = 10%
options(
  shinytest2.compare_screenshot.threshold = 187.5,
  shinytest2.compare_screenshot.kernel_size = 25
)

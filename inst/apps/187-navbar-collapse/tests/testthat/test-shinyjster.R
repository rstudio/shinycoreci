library(bslib)

shinycoreci::testthat_shinyjster("No theme", dimensions = "550x700")

local({
  old_theme <- bs_global_set(bs_theme(version = 4))
  on.exit(bs_global_set(old_theme))
  shinycoreci::testthat_shinyjster("bs4", dimensions = "550x700")
})

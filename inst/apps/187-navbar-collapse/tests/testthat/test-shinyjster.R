library(bslib)

browsers <- c("chrome", "firefox", "edge")
shinyjster::testthat_shinyjster("No theme", dimensions = "550x700", browsers = browsers)

local({
  old_theme <- bs_global_set(bs_theme())
  on.exit(bs_global_set(old_theme))
  shinyjster::testthat_shinyjster("bs4", dimensions = "550x700", browsers = browsers)
})

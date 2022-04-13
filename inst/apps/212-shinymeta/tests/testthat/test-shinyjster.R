skip_if_not(getRversion() >= "3.5" && .Platform$OS.type != "windows")

shinycoreci::testthat_shinyjster(browsers = c("chrome", "firefox"))

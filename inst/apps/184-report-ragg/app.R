library(shiny)
source("global.R")
# Current CRAN versions of showtext & ragg don't pair well together
showtext::showtext_auto(FALSE)
ragg_testing_app()

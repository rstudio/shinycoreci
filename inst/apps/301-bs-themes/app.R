library(shiny)
library(bslib)
library(thematic)
library(ggplot2)
library(DT)
library(reshape2)

# Get the 'original' version of this app from the bslib package
# (so we don't have to update tests/screenshots)
# https://github.com/rstudio/bslib/pull/572
Sys.setenv("BSLIB_LEGACY_THEMER_APP" = TRUE)
shinyAppDir(system.file("themer-demo", package = "bslib"))

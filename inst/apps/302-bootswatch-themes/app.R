library(shiny)
if (!require("bslib")) {
  remotes::install_github("rstudio/bslib")
}
if (!require("thematic")) {
  remotes::install_github("rstudio/thematic")
}
library(ggplot2)
library(sf)
library(DT)

shinyAppDir(system.file("themer-demo", package = "bslib"))

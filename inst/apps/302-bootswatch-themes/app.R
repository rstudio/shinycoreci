library(shiny)
if (!require("bslib")) {
  stop("bslib not installed")
}
if (!require("thematic")) {
  stop("thematic not installed")
}
library(ggplot2)
library(sf)
library(DT)
shinyAppDir(system.file("themer-demo", package = "bslib"))

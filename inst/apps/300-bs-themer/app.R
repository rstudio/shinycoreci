### Keep this line to manually test this shiny application. Do not edit this line; shinycoreci::::is_manual_app


library(bslib)

# used to find app deps
if (FALSE) {

  # system.file("themer-demo", package = "bslib") %>%
  #   renv::dependencies(
  #     ,
  #     quiet = TRUE
  #   ) %>%
  #   {.$Package} %>%
  #   unique() %>%
  #   sort() %>%
  #   paste0("library(", ., ")", collapse = "\n") %>%
  #   cat()

library(bslib)
library(curl)
library(DT)
library(ggplot2)
library(hexbin)
library(htmltools)
library(knitr)
library(lattice)
library(reactable)
library(rlang)
library(rprojroot)
library(rsconnect)
library(shiny)
library(thematic)
library(tools)

}

# Essentially the same as bs_theme_preview(), but deployable
old_theme <- bs_global_set(bs_theme())
onStop(function() {
  bs_global_set(old_theme)
})
bslib:::as_themer_app(system.file("themer-demo", package = "bslib"))

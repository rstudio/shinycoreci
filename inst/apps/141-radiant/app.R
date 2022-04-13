### Keep this line to manually test this shiny application. Do not edit this line; shinycoreci::::is_manual_app


## CRAN
# install.packages("radiant")

## Github instructions
# install.packages("radiant", repos = "https://radiant-rstats.github.io/minicran/")

library(radiant)

## Regular execution
# radiant::radiant()

# Retrieve the underlying shinyapp in radiant
shiny::shinyAppDir(system.file("app", package = "radiant"))

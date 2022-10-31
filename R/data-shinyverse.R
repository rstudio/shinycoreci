# Written by hand!

# Used by GHA script
shinyverse_remotes <- c(
  "r-lib/cachem",
  "r-lib/fastmap",
  "r-lib/later",
  "rstudio/bslib",
  "rstudio/crosstalk",
  "rstudio/DT",
  "rstudio/dygraphs",
  "rstudio/flexdashboard",
  "rstudio/fontawesome@v0.4.0-rc",
  "rstudio/htmltools",
  "rstudio/httpuv",
  "rstudio/leaflet",
  "rstudio/pool",
  "rstudio/promises",
  "rstudio/reactlog",
  "rstudio/sass",
  "rstudio/shiny@rc-v1.7.2.1",
  "rstudio/shinymeta",
  "rstudio/shinytest",
  "rstudio/shinytest2",
  "rstudio/shinythemes",
  "rstudio/shinyvalidate",
  "rstudio/thematic",
  "rstudio/webdriver",
  "rstudio/websocket",
  "schloerke/shinyjster",
  NULL
)

shinyverse_pkgs <- vapply(strsplit(shinyverse_remotes, "/"), `[[`, character(1), 2)

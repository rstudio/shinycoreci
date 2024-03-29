# Written by hand!

# Used by GHA script
shinyverse_remotes <- c(
  "r-lib/cachem",
  "r-lib/fastmap",
  "r-lib/later",
  "rstudio/bslib",
  "rstudio/bsicons",
  "ramnathv/htmlwidgets",
  "rstudio/crosstalk",
  "rstudio/gt",
  "rstudio/DT",
  "rstudio/dygraphs",
  "rstudio/flexdashboard",
  "rstudio/fontawesome",
  "rstudio/htmltools",
  "rstudio/httpuv",
  "rstudio/leaflet",
  "rstudio/pool",
  "rstudio/promises",
  "rstudio/reactlog",
  "rstudio/sass",
  "rstudio/shiny",
  "rstudio/shinymeta",
  "rstudio/shinytest",
  "rstudio/chromote",
  "rstudio/shinytest2",
  "rstudio/shinythemes",
  "rstudio/shinyvalidate",
  "rstudio/thematic",
  "rstudio/webdriver",
  "rstudio/websocket",
  "ropensci/plotly",
  "schloerke/shinyjster",
  NULL
)

shinyverse_pkgs <- vapply(strsplit(shinyverse_remotes, "/"), `[[`, character(1), 2)

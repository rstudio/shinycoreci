library(leaflet)

tagList(
  leaflet(quakes, width="100%", height="100%") %>%
      # addTiles() %>% # do not add tiles for CI purposes
      addMarkers(~ long, ~ lat),
  tags$style("html, body { width: 100%; height: 100%; }")
)

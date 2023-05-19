# 312-bslib-sidebar-resize

## Description

`312-bslib-sidebar-resize` tests that outputs and htmlwidgets inside the main content area of sidebar layouts animate through the sidebar resizing transition. The test app includes three pages:

1. A layout with two ggplot2 plots created via `plotOutput()`. During the sidebar resizing transition, the plots should stretch. This causes some visible distortion of the image. When the transition is complete, the server updates the plot at the new resolution and the image should "snap" into place.

2. A layout with two plotly plots created via `plotlyOutput()`. During the sidebar resizing transition, the plots should grow or shrink smoothly to match the available space in the content area of the layout.

3. A layout with two htmlwidgets created via `plot_ly()`. During the sidebar resizing transition, the widgets should grow or shrink smoothly to match the available space in the content area of the layout.

## Notes

The animation is not smooth on Windows, at least on CI. The test suite currently skips testing around the plot animation on Windows, but does test the sidebar state. Manual testing on Windows should confirm that the animation is smooth.

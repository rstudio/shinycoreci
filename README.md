<!-- README.md is generated from README.Rmd. Please edit that file -->

# shinycoreci

<!-- badges: start -->

[![Lifecycle Experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![R CMD check](https://github.com/rstudio/shinycoreci/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/rstudio/shinycoreci/actions/workflows/R-CMD-check.yaml)
[![Warm library cache](https://github.com/rstudio/shinycoreci/actions/workflows/apps-cache-matrix.yml/badge.svg)](https://github.com/rstudio/shinycoreci/actions/workflows/apps-cache-matrix.yml)
[![Test](https://github.com/rstudio/shinycoreci/actions/workflows/apps-test-matrix.yml/badge.svg)](https://github.com/rstudio/shinycoreci/actions/workflows/apps-test-matrix.yml)
[![Deploy](https://github.com/rstudio/shinycoreci/actions/workflows/apps-deploy.yml/badge.svg)](https://github.com/rstudio/shinycoreci/actions/workflows/apps-deploy.yml)
[![Docker](https://github.com/rstudio/shinycoreci/actions/workflows/apps-docker.yml/badge.svg)](https://github.com/rstudio/shinycoreci/actions/workflows/apps-docker.yml)
[![Dependencies](https://github.com/rstudio/shinycoreci/actions/workflows/apps-deps.yml/badge.svg)](https://github.com/rstudio/shinycoreci/actions/workflows/apps-deps.yml)
<!-- badges: end -->

<!-- This is an R package to install all dependencies to test the bleeding edge of all relevant packages to the Shiny team. -->

<!-- For more direct usage examples, see [`rstudio/shinycoreci-apps`](https://github.com/rstudio/shinycoreci-apps). -->

## Installation

Install the development version from [GitHub](https://github.com/) with:

``` r
# install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch))
pak::pkg_install("rstudio/shinycoreci")
```

These GitHub packages will be installed to make sure the latest package development is working as expected:

  - [r-lib/cachem](http://github.com/r-lib/cachem)
  - [r-lib/fastmap](http://github.com/r-lib/fastmap)
  - [r-lib/later](http://github.com/r-lib/later)
  - [rstudio/bslib](http://github.com/rstudio/bslib)
  - [rstudio/crosstalk](http://github.com/rstudio/crosstalk)
  - [rstudio/DT](http://github.com/rstudio/DT)
  - [rstudio/dygraphs](http://github.com/rstudio/dygraphs)
  - [rstudio/flexdashboard](http://github.com/rstudio/flexdashboard)
  - [rstudio/fontawesome](http://github.com/rstudio/fontawesome)
  - [rstudio/htmltools](http://github.com/rstudio/htmltools)
  - [rstudio/httpuv](http://github.com/rstudio/httpuv)
  - [rstudio/pool](http://github.com/rstudio/pool)
  - [rstudio/promises](http://github.com/rstudio/promises)
  - [rstudio/reactlog](http://github.com/rstudio/reactlog)
  - [rstudio/rsconnect](http://github.com/rstudio/rsconnect)
  - [rstudio/sass](http://github.com/rstudio/sass)
  - [rstudio/shiny](http://github.com/rstudio/shiny)
  - [rstudio/shinymeta](http://github.com/rstudio/shinymeta)
  - [rstudio/shinytest](http://github.com/rstudio/shinytest)
  - [rstudio/shinytest2](http://github.com/rstudio/shinytest2)
  - [rstudio/shinythemes](http://github.com/rstudio/shinythemes)
  - [rstudio/shinyvalidate](http://github.com/rstudio/shinyvalidate)
  - [rstudio/thematic](http://github.com/rstudio/thematic)
  - [rstudio/webdriver](http://github.com/rstudio/webdriver)
  - [rstudio/websocket](http://github.com/rstudio/websocket)
  - [schloerke/shinyjster](http://github.com/schloerke/shinyjster)

## FAQ:

If you run into an odd `{pak}` installation issue:

  - Run `pak::cache_clean()` to clear the cache and try your original command again

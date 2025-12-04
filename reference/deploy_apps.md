# Deploy apps to a server

Run this in the terminal (not RStudio IDE) as it has issues when
installing some packages.

## Usage

``` r
deploy_apps(
  apps = apps_deploy,
  account = "testing-apps",
  server = "shinyapps.io",
  ...,
  local_pkgs = FALSE,
  extra_packages = NULL,
  cores = 1,
  retry = 2,
  retrying_ = FALSE
)
```

## Arguments

- apps:

  A character vector of fully defined shiny application folders

- account, server:

  args supplied to `[rsconnect::deployApp]`

- ...:

  ignored

- local_pkgs:

  If `TRUE`, local packages will be used instead of the isolated
  shinyverse installation.

- extra_packages:

  A character vector of extra packages to install

- cores:

  number of cores to use when deploying

- retry:

  If `TRUE`, try failure apps again. (Only happens once.)

- retrying\_:

  For internal use only

## Details

Installation will use default libpaths.

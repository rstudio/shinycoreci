# Test apps within the terminal

Automatically runs the next app in a fresh callr::r_bg session. To stop,
close the shiny application window.

## Usage

``` r
test_in_browser(
  app_name = apps[1],
  apps = apps_manual,
  ...,
  port = 8080,
  port_background = NULL,
  host = "127.0.0.1",
  local_pkgs = FALSE
)
```

## Arguments

- app_name:

  app number or name to start with. If numeric, it will match the
  leading number in the testing application

- apps:

  List of apps to test

- ...:

  ignored

- port:

  `port` for the foreground app process

- port_background:

  `port` for the background app process

- host:

  `host` for the foreground and background app processes

- local_pkgs:

  If `TRUE`, local packages will be used instead of the isolated
  shinyverse installation.

## Examples

``` r
if (FALSE) { # \dontrun{
test_in_browser()
} # }
```

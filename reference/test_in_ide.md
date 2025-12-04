# Test apps within RStudio IDE

Automatically runs the next app in a fresh RStudio session after closing
the current app. To stop, send an interrupt signal (`esc` or `ctrl+c`)
to the app twice in rapid succession.

## Usage

``` r
test_in_ide(
  app_name = apps[1],
  apps = apps_manual,
  ...,
  port = 8000,
  host = "127.0.0.1",
  delay = 1,
  local_pkgs = FALSE,
  viewer = NULL,
  refresh_ = FALSE
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

- host:

  `host` for the foreground and background app processes

- delay:

  Time to wait between applications. \[`1`\]

- local_pkgs:

  If `TRUE`, local packages will be used instead of the isolated
  shinyverse installation.

- viewer:

  RStudio IDE viewer to use. \[`"pane"`\]

- refresh\_:

  For internal use. If TRUE, packages will not be reinstalled.

## Details

Kill testing by hitting `esc` in RStudio.

If [`options()`](https://rdrr.io/r/base/options.html) need to be set,
set them in your

    .Rprofile

file. See `usethis::edit_r_profile()`

## Examples

``` r
if (FALSE) { # \dontrun{
test_in_ide(dir = "apps")
} # }
```

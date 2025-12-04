# Test deployed apps

Opens an app on the hosted server and runs silbing apps in an iframe.

## Usage

``` r
test_in_connect(type = c("manual", "all"))

test_in_shinyappsio(type = c("manual", "all"))
```

## Arguments

- type:

  Type of apps to test. `"manual"` (default) will only contain apps that
  should be manually tested. `"all"` will contain all apps that have
  been deployed. This is every app except for `141-radiant`.

## Functions

- `test_in_connect()`: Test deployed applications on RStudio Connect

- `test_in_shinyappsio()`: Test connect applications given the server
  and account

## Examples

``` r
if (FALSE) test_in_connect() # \dontrun{}
if (FALSE) test_in_test_in_shinyapps_io() # \dontrun{}
```

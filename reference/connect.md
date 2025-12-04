# Make Connect Shiny applications publically available

The corresponding `rsconnect` account should already exist before
calling `connect_set_public`. This can be done by calling
[`rsconnect::connectApiUser`](https://rstudio.github.io/rsconnect/reference/connectApiUser.html)
to add the appropriate account information.

## Usage

``` r
connect_set_public(
  apps = apps_shiny,
  account = "barret",
  server = "beta.rstudioconnect.com"
)

connect_urls(
  apps = apps_deploy,
  account = "barret",
  server = "beta.rstudioconnect.com"
)
```

## Arguments

- apps:

  A character vector of fully defined shiny application folders

- account, server:

  args supplied to `[rsconnect::deployApp]`

## Functions

- `connect_set_public()`: Set all the Shiny apps to be public on a
  Connect server

- `connect_urls()`: Retrieve the urls from a Connect server using the
  Shiny applications provided in `dir`

## Examples

``` r
if (FALSE) { # \dontrun{
  rsconnect::addConnectServer(url = 'https://SERVER.com/API', name = 'CustomName')
  rsconnect::connectApiUser('barret', 'CustomName', apiKey = 'SuperSecretKey')
  deploy_apps(account = 'barret', server = 'CustomName')
  connect_set_public(account = 'barret', server = 'CustomName')
  urls <- connect_urls(account = 'barret', server = 'CustomName')
} # }
```

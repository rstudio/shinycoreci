# Test Apps in SSO/SSP

Automatically launches docker in a background process. Once the docker
is ready, a shiny application will be launched to help move through the
applications.

## Usage

``` r
test_in_sso(
  app_name = apps[1],
  apps = apps_manual,
  ...,
  user = github_user(),
  release = c("jammy", "focal", "centos7"),
  r_version = c("4.3", "4.2", "4.1", "4.0", "3.6"),
  tag = NULL,
  port = 8080,
  port_background = switch(release, centos7 = 7878, 3838),
  host = "127.0.0.1"
)

test_in_ssp(
  app_name = apps[1],
  apps = apps_manual,
  ...,
  license_file = NULL,
  user = github_user(),
  release = c("jammy", "focal", "centos7"),
  r_version = c("4.3", "4.2", "4.1", "4.0", "3.6"),
  tag = NULL,
  port = 8080,
  port_background = switch(release, centos7 = 8989, 4949),
  host = "127.0.0.1"
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

- user:

  GitHub username. Ex: `schloerke`. Uses
  [`github_user`](https://rstudio.github.io/shinycoreci/reference/github_user.md)
  by default

- release:

  Distro release name, such as "focal" for ubuntu or "7" for centos

- r_version:

  R version to use. Ex: `"3.6"`

- tag:

  Extra tag information for the docker image. This will prepend a `-` if
  a value is given.

- port:

  Port for local shiny application

- port_background:

  Port to connect to the Docker container

- host:

  `host` for the foreground and background app processes

- license_file:

  Path to a SSP license file

## Details

The docker application will stop when the shiny application exits.

## Functions

- `test_in_sso()`: Test SSO Shiny applications

- `test_in_ssp()`: Test SSP Shiny applications

## Examples

``` r
if (FALSE) test_in_sso() # \dontrun{}
if (FALSE) test_in_ssp() # \dontrun{}
```

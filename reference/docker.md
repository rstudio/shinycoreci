# Docker Testing

Docker Testing

## Usage

``` r
docker_run_sso(
  release = c("focal", "bionic", "centos7"),
  port = switch(release, centos7 = 7878, 3838),
  r_version = c("4.1", "4.0", "3.6", "3.5"),
  tag = NULL,
  launch_browser = TRUE
)

docker_run_ssp(
  release = c("focal", "bionic", "centos7"),
  port = switch(release, centos7 = 8989, 4949),
  r_version = c("4.1", "4.0", "3.6", "3.5"),
  tag = NULL,
  launch_browser = TRUE
)
```

## Arguments

- release:

  Distro release name, such as "focal" for ubuntu or "7" for centos

- port:

  port to have server function locally

- r_version:

  R version to use. Ex: `"3.6"`

- tag:

  Extra tag information for the docker image. This will prepend a `-` if
  a value is given.

- launch_browser:

  Logical variable that determines if the browser should open to the
  specified port location

## Functions

- `docker_run_sso`: Run SSO in a docker container

- `docker_run_ssp`: Run SSP in a docker container

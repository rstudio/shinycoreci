

#' Clean up docker files
#'
#' @param stopped_containers boolean that determines if all stopped containers should be removed
#' @param untagged_images boolean that determines of all untagged images should be removed
#' @export
docker_clean <- function(stopped_containers = TRUE, untagged_images = TRUE) {
  if (isTRUE(stopped_containers)) {
    message("Removing stopped containers")
    try(docker_cmd("docker container prune --force"))
  }
  if (isTRUE(untagged_images)) {
    message("Removing untagged images")
    try(docker_cmd("docker rmi $(docker images --filter 'dangling=true' -q --no-trunc)"))
  }
  invisible()
}



#' Docker Testing
#'
#' @param r_version R version to use. Ex: \code{"3.6"}
#' @param release Distro release name, such as "bionic" for ubuntu or "7" for centos
#' @param port port to have server function locally
#' @param launch_browser Logical variable that determines if the browser should open to the specified port location
#' @describeIn docker Run SSO in a docker container
#' @export
docker_run_sso <- function(
  release = c("bionic", "xenial", "centos7"),
  port = switch(release, "centos7" = 7878, 3838),
  r_version = "3.6",
  launch_browser = TRUE
) {
  release <- match.arg(release)
  r_version <- match.arg(r_version)

  docker_run_server(
    type = "sso",
    release = release,
    port = port,
    r_version = r_version,
    launch_browser = launch_browser
  )
}



#' @describeIn docker Run SSP in a docker container
#' @export
docker_run_ssp <- function(
  release = c("bionic", "xenial", "centos7"),
  port = switch(release, "centos7" = 8989, 4949),
  r_version = "3.6",
  launch_browser = TRUE
) {
  release <- match.arg(release)
  r_version <- match.arg(r_version)

  docker_run_server(
    type = "ssp",
    release = release,
    port = port,
    r_version = r_version,
    launch_browser = launch_browser
  )
}




docker_run_server <- function(
  type = c("sso", "ssp"),
  release = c("bionic", "xenial", "centos7"),
  port = switch(type,
                sso = switch(release, "centos7" = 7878, 3838),
                ssp = switch(release, "centos7" = 8989, 4949)
                ),
  r_version = "3.6",
  launch_browser = launch_browser
) {
  tag <- paste0(type, "-", r_version, "-", release)
  docker_cmd(
    "docker pull rstudio/shinycoreci:", tag
  )
  if (isTRUE(launch_browser)) {
    utils::browseURL(paste0("http://localhost:", port, "/"))
  }
  docker_cmd(
    "docker run --rm -p ", port, ":3838 --name ", type, "_", r_version, "_", release, " rstudio/shinycoreci:", tag
  )
}

docker_cmd <- function(...) {
  cmd <- paste0(...)
  print(cmd)
  ret <- system(cmd)
  if (ret != 0 && ret != 2) {
    # 0 is success
    # 2 is interrupt
    stop("docker command failed")
  }
}

## To run bash in a docker file...
# docker run --rm -ti --name NAME DOCKERFILE
# docker exec -ti NAME /bin/bash  # Another terminal into the container


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
#' @param release Distro release name, such as "focal" for ubuntu or "7" for centos
#' @param port port to have server function locally
#' @param tag Extra tag information for the docker image. This will prepend a \verb{-} if a value is given.
#' @param launch_browser Logical variable that determines if the browser should open to the specified port location
#' @describeIn docker Run SSO in a docker container
#' @export
docker_run_sso <- function(
  release = c("focal", "bionic", "centos7"),
  port = switch(release, "centos7" = 7878, 3838),
  r_version = c("4.1", "4.0", "3.6", "3.5"),
  tag = NULL,
  launch_browser = TRUE
) {
  release <- match.arg(release)
  r_version <- match.arg(r_version)

  docker_run_server(
    type = "sso",
    release = release,
    port = port,
    r_version = r_version,
    tag = tag,
    launch_browser = launch_browser
  )
}



#' @describeIn docker Run SSP in a docker container
#' @export
docker_run_ssp <- function(
  release = c("focal", "bionic", "centos7"),
  port = switch(release, "centos7" = 8989, 4949),
  r_version = c("4.1", "4.0", "3.6", "3.5"),
  tag = NULL,
  launch_browser = TRUE
) {
  release <- match.arg(release)
  r_version <- match.arg(r_version)

  docker_run_server(
    type = "ssp",
    release = release,
    port = port,
    r_version = r_version,
    tag = tag,
    launch_browser = launch_browser
  )
}




docker_run_server <- function(
  type = c("sso", "ssp"),
  release = c("focal", "bionic", "centos7"),
  port = switch(type,
                sso = switch(release, "centos7" = 7878, 3838),
                ssp = switch(release, "centos7" = 8989, 4949)
                ),
  r_version = c("4.1", "4.0", "3.6", "3.5"),
  tag = NULL,
  launch_browser = launch_browser
) {
  type <- match.arg(type)
  release <- match.arg(release)
  r_version <- match.arg(r_version)

  tag <- paste0(type, "-", r_version, "-", release, if(!is.null(tag)) paste0("-", tag))
  docker_cmd(
    "docker pull rstudio/shinycoreci:", tag
  )
  if (isTRUE(launch_browser)) {
    utils::browseURL(paste0("http://localhost:", port, "/"))
  }

  # -t   = pseudo-TTY https://stackoverflow.com/a/33027467/591574 needed for ./retail cmd
  docker_cmd(
    "docker run -t --rm -p ", port, ":3838 --name ", type, "_", r_version, "_", release, " rstudio/shinycoreci:", tag
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

docker_stop <- function(type, r_version, release) {
  docker_cmd(
    "docker stop ", type, "_", r_version, "_", release
  )
}

docker_is_alive <- function() {
  ret <- system("docker ps", ignore.stdout = TRUE, ignore.stderr = TRUE)
  ret == 0
}
docker_is_logged_in <- function(user = github_user()) {
  # if already logged in, it will return a 0
  # if not logged in, it will fail and return a 1
  withr::with_options(list(warn = 2), {
    ret <- system(paste0("echo $GITHUB_PAT | docker login ghcr.io -u \"", user, "\" --password-stdin"))
    ret == 0
  })
}

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


docker_run_server <- function(
  type = c("sso", "ssp"),
  release = c("focal", "bionic", "centos7"),
  license_file = NULL,
  port = switch(type,
                sso = switch(release, "centos7" = 7878, 3838),
                ssp = switch(release, "centos7" = 8989, 4949)
                ),
  r_version = c("4.2", "4.1", "4.0", "3.6", "3.5"),
  tag = NULL,
  launch_browser = launch_browser,
  user = github_user()
) {
  type <- match.arg(type)
  release <- match.arg(release)
  r_version <- match.arg(r_version)

  mount_args <- ""
  if (type == "ssp") {
    if (is.null(license_file)) {
      stop("`license_file` is required")
    }
    if (!file.exists(license_file)) {
      stop("`license_file` must exist")
    }

    # Copy license file to tmpfolder as `ssp.lic`
    license_folder <- tempfile("sci-")
    dir.create(license_folder)
    withr::defer({
      unlink(license_folder)
    })
    file.copy(license_file, file.path(license_folder, "ssp.lic"))

    mount_args <- paste0(
      # Mount Volume
      "-v ",
      # LOCAL:DESTINATION
      license_folder, ":/opt/license",
      # Read Only
      ":ro",
      # Spacer
      " "
    )

  }

  tag <- paste0(type, "-", r_version, "-", release, if(!is.null(tag)) paste0("-", tag))
  if (!docker_is_logged_in(user = user)) {
    stop("Docker is not logged in to the ghcr.io registry")
  }
  message("Pulling Docker image. This may take a minute...")
  docker_cmd(
    "docker pull ghcr.io/rstudio/shinycoreci:", tag
  )
  if (isTRUE(launch_browser)) {
    utils::browseURL(paste0("http://localhost:", port, "/"))
  }

  # -t   = pseudo-TTY https://stackoverflow.com/a/33027467/591574 needed for ./retail cmd
  docker_cmd(
    "docker run ",
    "-t ",
    "--rm ",
    mount_args,
    "-p ", port, ":3838 ",
    "--name ", type, "_", r_version, "_", release, " ",
    "ghcr.io/rstudio/shinycoreci:", tag
  )
}

docker_cmd <- function(...) {
  cmd <- paste0(...)
  cat("Running: ", cmd, "\n", sep = "")
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

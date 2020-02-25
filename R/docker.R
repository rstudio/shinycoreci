#' @importFrom magrittr %>%
NULL


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
#' @param r_version R version to use. Ex: 3.6
#' @param distro Distro name
#' @param release Distro release name, such as "bionic" for ubuntu or "7" for centos
#' @param port port to have server function locally
#' @param examples_repo shiny examples github repo location
#' @param testing_repo testing github repo to download
#' @param auth_token github PAT.  See \code{?usethis::github_token}
#' @param launch_browser boolean that determines if browser is launched
#' @describeIn docker Run SSO in a docker container
#' @export
docker_run_sso <- function(
  r_version = "3.6",
  distro = c("ubuntu", "centos"),
  release = if (distro == "ubuntu") "bionic" else "7",
  port = if (distro == "ubuntu") 3838 else 7878,
  examples_repo = "rstudio/shiny-examples",
  testing_repo = "rstudio/testShinyExamples",
  auth_token = remotes:::github_pat(),
  launch_browser = interactive()
) {
  distro <- match.arg(distro)

  docker_run_sso_ssp(
    r_version = r_version,
    distro = distro,
    release = release,
    port = port,
    sso_ssp = "sso",
    testing_repo = testing_repo,
    examples_repo = examples_repo,
    auth_token = auth_token,
    launch_browser = launch_browser
  )
}
#' @describeIn docker Run SSP in a docker container
#' @export
docker_run_ssp <- function(
  r_version = "3.6",
  distro = c("ubuntu", "centos"),
  release = if (distro == "ubuntu") "bionic" else "7",
  port = if (distro == "ubuntu") 3939 else 7979,
  examples_repo = "rstudio/shiny-examples",
  testing_repo = "rstudio/testShinyExamples",
  auth_token = remotes:::github_pat(),
  launch_browser = interactive()
) {
  distro <- match.arg(distro)

  docker_run_sso_ssp(
    r_version = r_version,
    distro = distro,
    release = release,
    port = port,
    sso_ssp = "ssp",
    testing_repo = testing_repo,
    examples_repo = examples_repo,
    auth_token = auth_token,
    launch_browser = launch_browser
  )
}

docker_run_sso_ssp <- function(
  r_version = "3.6",
  distro = c("ubuntu", "centos"),
  release = if (distro == "ubuntu") "bionic" else "7",
  port = 1234,
  sso_ssp = c("sso", "ssp"),
  testing_repo = "rstudio/testShinyExamples",
  examples_repo = "rstudio/shiny-examples",
  auth_token = remotes:::github_pat(),
  launch_browser = interactive()
) {
  distro <- match.arg(distro)
  sso_ssp <- match.arg(sso_ssp)

  docker_build_sso_ssp(
    r_version = r_version,
    distro = distro,
    release = release,
    sso_ssp = sso_ssp,
    testing_repo = testing_repo,
    examples_repo = examples_repo,
    auth_token = auth_token
  )
  if (isTRUE(launch_browser)) browseURL(paste0("http://127.0.0.1:", port))
  docker_release <- docker_release_val(distro, release)
  docker_run_cmd(
    r_version, docker_release,
    build = paste0("tse/", sso_ssp),
    port = port,
    TEST_SHINY_REPO = testing_repo,
    SHINY_EXAMPLES_REPO = examples_repo
  )
}

docker_build_distro <- function(
  r_version = "3.6",
  distro = c("ubuntu", "centos"),
  release = if (distro == "ubuntu") "bionic" else "7",
  testing_repo = "rstudio/testShinyExamples",
  examples_repo = "rstudio/shiny-examples",
  auth_token = remotes:::github_pat()
) {
  distro <- match.arg(distro)
  template_folder <- paste0("docker_", distro)

  docker_release <- docker_release_val(distro, release)

  # docker_update_file(
  #   template_folder = template_folder,
  #   r_version = r_version,
  #   docker_release = docker_release,
  #   pre_install_scripts = rspm_pre_install_scripts(
  #     distro = distro, release = release,
  #     examples_repo = examples_repo
  #   ),
  #   install_scripts = rspm_install_scripts(
  #     distro = distro, release = release,
  #     examples_repo = examples_repo
  #   )
  # )
  docker_build_cmd(
    r_version,
    docker_release,
    paste0("tse/", distro),
    template_folder,
    " --build-arg GITHUB_PAT=", auth_token,
    " --build-arg TEST_SHINY_REPO=",   remote_with_sha(testing_repo),
    " --build-arg SHINY_EXAMPLES_REPO=", examples_repo
  )
}


docker_build_sso_ssp <- function(
  r_version = "3.6",
  distro = c("ubuntu", "centos"),
  release = if (distro == "ubuntu") "bionic" else "7",
  sso_ssp = c("sso", "ssp"),
  testing_repo = "rstudio/testShinyExamples",
  examples_repo = "rstudio/shiny-examples",
  auth_token = remotes:::github_pat()
) {

  distro <- match.arg(distro)
  sso_ssp <- match.arg(sso_ssp)

  docker_release <- switch(distro, "centos" = paste0("centos", release), release)

  docker_build_distro(
    r_version = r_version,
    distro = distro,
    release = release,
    testing_repo = testing_repo,
    examples_repo = examples_repo,
    auth_token = auth_token
  )

  docker_folder <- paste0("docker_", distro, "_", sso_ssp)
  docker_update_file(
    docker_folder,
    r_version = r_version,
    docker_release = docker_release,
    sso_build_machine_version = switch(distro,
      "ubuntu" = switch(release, "xenial" = "ubuntu-12.04", "ubuntu-14.04"),
      "centos" = switch(release, "7" = "centos6.3", stop("UNKNOWN CENTOS VERSION!"))
    )
  )
  docker_build_cmd(
    r_version, docker_release,
    paste0("tse/", sso_ssp),
    docker_folder
  )
}


docker_build_cmd <- function(r_version, release, docker_name, file_name, ...) {
  str(file_name)
  docker_name <- docker_build_name(docker_name, r_version, release)

  message("Building ", docker_name)
  cmd <- paste0(
    "docker build -t ", docker_name, " ", ..., " ", system.file("docker", file_name, package = "testShinyExamples")
  )
  docker_cmd(cmd)
}
docker_run_cmd <- function(r_version, release, build, port, TEST_SHINY_REPO, SHINY_EXAMPLES_REPO) {
  build <- docker_build_name(build, r_version, release)
  name <- gsub("[^a-zA-Z0-9]", "_", build)
  on.exit({
    # make sure the container is stopped
    docker_stop(name)
  })

  cmd <- paste0(
    # -t   = pseudo-TTY https://stackoverflow.com/a/33027467/591574 needed for ./retail cmd
    "docker run -t --rm -p ", port, ":3838",
    " --name ", name, " ",
    " --env TEST_SHINY_REPO='", TEST_SHINY_REPO, "'",
    " --env SHINY_EXAMPLES_REPO='", SHINY_EXAMPLES_REPO, "'",
    " ", build
  )
  docker_cmd(cmd)
}


docker_update_file <- function(template_folder = "docker_ubuntu", ...) {
  txt <- system.file(
    file.path("docker", template_folder, "Dockerfile_template"),
    package = "testShinyExamples"
  ) %>%
    readLines() %>%
    paste0(collapse = "\n")

  glue::glue_data(
      list(
        ...
      ),
      txt,
      .open = "{{", .close = "}}"
    ) %>%
    writeLines(
      system.file(
        file.path("docker", template_folder, "Dockerfile"),
        package = "testShinyExamples"
      )
    )
}


docker_cmd <- function(cmd) {
  print(cmd)
  ret <- system(cmd)
  if (ret != 0 && ret != 2) {
    # 0 is success
    # 2 is interrupt
    stop("docker command failed")
  }
}


docker_stop <- function(name) {
  message("Stopping ", name)
  try(docker_cmd(paste0("docker stop $(docker ps -q -f 'name=", name, "')")))
}

docker_build_name <- function(name, r_version, release) {
  paste0(name, ":", r_version, "-", release)
}
docker_release_val <- function(distro, release) {
  switch(distro, "centos" = paste0("centos", release), release)
}

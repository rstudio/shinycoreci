
# Info
#   https://packagemanager.rstudio.com/client/#/repos/3/overview
# Has ID
#   https://packagemanager.rstudio.com/__api__/repos/4/packages?name=highcharter
# Has sys reqs
#   https://packagemanager.rstudio.com/__api__/repos/4/packages/highcharter/sysreqs?id=593567&distribution=ubuntu&release=18.04

# used in docker files

#' RStudio Package Manager System Install Scripts
#'
#' @inheritParams apps_runtests
#' @param release Docker release to use. Such as \verb{'bionic'} or \verb{'centos7'}
#' @describeIn rspm_install Install script needed for R packages to run
#' @export
rspm_install_scripts <- function(
  dir = "apps",
  release = c("bionic", "xenial", "centos7")
) {
  ret <- rspm_sys_reqs(
    dir = dir,
    release = match.arg(release)
  )
  ret$install_scripts
}
#' @describeIn rspm_install Install script needed for R packages to install
#' @export
rspm_pre_install_scripts <- function(
  dir = "apps",
  release = c("bionic", "xenial", "centos7")
) {
  ret <- rspm_sys_reqs(
    dir = dir,
    release = match.arg(release)
  )
  ret$pre_install_scripts
}
#' @describeIn rspm_install All install script needed for R packages
#' @export
rspm_all_install_scripts <- function(
  dir = "apps",
  release = c("bionic", "xenial", "centos7")
) {
  ret <- rspm_sys_reqs(
    dir = dir,
    release = match.arg(release)
  )
  ret$all_install_scripts
}

rspm_sys_reqs <- function(
  dir = "apps",
  release = c("bionic", "xenial", "centos7")
) {

  release <- match.arg(release)
  distro_val <- rspm_distro(release)
  release_val <- rspm_release(release)

  message("Retrieving dependencies...")
  deps <- app_deps(dir)$package

  message("Query RSPM...")
  pr <- progress_bar(
    total = length(deps),
    format = paste0("[:current/:total, :eta/:elapsed] RSPM ", distro_val, "-", release_val, " deps: :name")
  )
  reqs <- lapply(deps, function(dep) {
    pr$tick(tokens = list(name = dep))
    tryCatch({
      rspm_pkg_reqs(dep, distro_val, release_val)
    }, error = function(e) {
      message("Error for dep '", dep, "'. Error: ", e)
      NULL
    })
  })

  list(
    pre_install_scripts = rspm_output_txt(reqs, "pre_install", distro_val = distro_val),
    install_scripts = rspm_output_txt(reqs, "install_scripts", distro_val = distro_val),
    all_install_scripts = rspm_output_txt(reqs, c("pre_install", "install_scripts"), distro_val = distro_val)
  )
}

rspm_pkg_reqs <- function(pkg_name, distro_val, release_val) {

  # id <-
  #   paste0("https://packagemanager.rstudio.com/__api__/repos/1/packages?name=", pkg_name) %>%
  #   jsonlite::fromJSON(simplifyDataFrame = FALSE) %>%
  #   magrittr::extract2(1) %>%
  #   magrittr::extract2("id")

  info <- jsonlite::fromJSON(
    paste0(
      "https://packagemanager.rstudio.com/__api__/repos/1/packages/", pkg_name, "/sysreqs",
      "?distribution=", distro_val,
      "&release=", release_val
    ),
    simplifyDataFrame = FALSE
  )

  list(
    pre_install = rspm_output(info, "pre_install"),
    install_scripts = rspm_output(info, "install_scripts")
  )
}


rspm_release <- function(distro) {
  switch(distro,
    "xenial" = "16.04",
    "bionic" = "18.04",
    "centos6" = "6",
    "centos7" = "7",
    "centos8" = "8",
    stop("Unknown distro: ", distro)
  )
}
rspm_distro <- function(distro) {
  switch(distro,
    "xenial" = ,
    "bionic" = "ubuntu",
    "centos6" = ,
    "centos7" = ,
    "centos8" = "centos",
    stop("Unknown distro: ", distro)
  )
}


rspm_output <- function(info, key) {
  unique(c(
    info[[key]],
    unlist(lapply(info$dependencies, `[[`, key))
  ))
}
rspm_output_txt <- function(reqs, keys, distro_val) {
  txt <- sort(unique(unlist(
    lapply(keys, function(key) {
      lapply(reqs, `[[`, key)
    })
  )))

  if (length(txt) == 0) {
    return("")
  }

  install_txt <- switch(
    distro_val,
    "centos" = "yum install -y ",
    "ubuntu" = "apt-get install -y ",
    stop("unknown distro: ", distro_val)
  )
  txt <- paste0(sub(install_txt, "", txt), collapse = " ")

  paste0(
    # "RUN ",
    install_txt,
    txt
  )
}

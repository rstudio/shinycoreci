#' Retrieve default GitHub username
#'
#' Equivalent to the terminal code: `git config github.user`
#' @export
github_user <- function() {
  system("git config github.user", intern = TRUE)
}


#' Test Apps in SSO/SSP
#'
#' Automatically launches docker in a background process.  Once the docker is ready, a shiny application will be launched to help move through the applications.
#'
#' The docker application will stop when the shiny application exits.
#'
#' @inheritParams test_in_browser
#' @param r_version R version to use. Ex: \code{"3.6"}
#' @param release Distro release name, such as "focal" for ubuntu or "7" for centos
#' @param port port to have server function locally
#' @param tag Extra tag information for the docker image. This will prepend a \verb{-} if a value is given.
#' @param user GitHub username. Ex: `schloerke`. Uses [`github_user`] by default
#' @param port Port for local shiny application
#' @param port_background Port to connect to the Docker container
#' @export
#' @describeIn test_in_ssossp Test SSO Shiny applications
#' @examples
#' \dontrun{test_in_sso()}
#' \dontrun{test_in_ssp()}
test_in_sso <- function(
  app_name = apps[1],
  apps = apps_manual,
  ...,
  user = github_user(),
  release = c("focal", "bionic", "centos7"),
  r_version = c("4.2", "4.1", "4.0", "3.6", "3.5"),
  tag = NULL,
  port = 8080,
  port_background = switch(release, "centos7" = 7878, 3838),
  host = "127.0.0.1"
) {
  release <- match.arg(release)

  test_in_ssossp(
    user = user,
    app_name = app_name,
    apps = apps,
    type = "sso",
    release = release,
    port_background = port_background,
    r_version = match.arg(r_version),
    tag = NULL,
    host = host,
    port = port
  )
}
#' @export
#' @param license_file Path to a SSP license file
#' @describeIn test_in_ssossp Test SSP Shiny applications
test_in_ssp <- function(
  app_name = apps[1],
  apps = apps_manual,
  ...,
  license_file = NULL,
  user = github_user(),
  release = c("focal", "bionic", "centos7"),
  r_version = c("4.2", "4.1", "4.0", "3.6", "3.5"),
  tag = NULL,
  port = 8080,
  port_background = switch(release, "centos7" = 8989, 4949),
  host = "127.0.0.1"
) {
  release <- match.arg(release)

  test_in_ssossp(
    user = user,
    app_name = app_name,
    apps = apps,
    type = "ssp",
    release = release,
    license_file = license_file,
    port_background = port_background,
    r_version = match.arg(r_version),
    tag = NULL,
    host = host,
    port = port
  )
}



  # type = c("sso", "ssp"),
  # release = c("focal", "bionic", "centos7"),
  # port = switch(type,
  #               sso = switch(release, "centos7" = 7878, 3838),
  #               ssp = switch(release, "centos7" = 8989, 4949)
  #               ),
  # r_version = c("3.6", "3.5"),
  # tag = NULL,
  # launch_browser = launch_browser


test_in_ssossp <- function(
  user = github_user(),
  app_name = apps[1],
  apps = apps_manual,
  type = c("sso", "ssp"),
  release = c("focal", "bionic", "centos7"),
  license_file = NULL,
  port_background = switch(type,
                sso = switch(release, "centos7" = 7878, 3838),
                ssp = switch(release, "centos7" = 8989, 4949)
                ),
  r_version = c("4.2", "4.1", "4.0", "3.6", "3.5"),
  tag = NULL,
  host = "127.0.0.1",
  port = 8080
) {
  # validate_core_pkgs()

  apps <- resolve_app_name(apps)

  type <- match.arg(type)
  release <- match.arg(release)
  force(port_background)
  r_version <- match.arg(r_version)

  radiant_app <- "141-radiant"
  if (radiant_app %in% apps) {
    message("\n!!! Radiant app being removed. It does not play well with centos7 !!!\n")
    apps <- setdiff(apps, radiant_app)
    if (identical(app_name, radiant_app)) {
      app_name <- apps[1]
    }
  }

  message("Verify Docker port is available...", appendLF = FALSE)
  conn_exists <- tryCatch({
    httr::GET(paste0("http://127.0.0.1:", port_background))
    # connection exists
    TRUE
  }, error = function(e) {
    # nothing exists
    FALSE
  })
  if (conn_exists) {
    message("")
    stop("Port ", port_background, " is busy. Maybe stop all other docker files? (`docker stop NAME`) Can inspect with `docker ps` in terminal.")
  }
  message(" OK")

  message("Starting Docker...")
  if (!docker_is_alive()) {
    stop("Cannot connect to the Docker daemon. Is the docker daemon running?")
  }
  if (!docker_is_logged_in()) {
    stop("Docker is not logged in. Please run `docker login` in the terminal with your Docker Hub username / password")
  }

  docker_proc <- callr::r_bg(
    function(type_, release_, license_file_, port_, r_version_, tag_, launch_browser_, docker_run_server_) {
      docker_run_server_(
        type = type_,
        release = release_,
        license_file = license_file_,
        port = port_,
        r_version = r_version_,
        tag = tag_,
        launch_browser = launch_browser_
      )
    },
    list(
      type_ = type,
      release_ = release,
      license_file_ = license_file,
      port_ = port_background,
      r_version_ = r_version,
      tag_ = tag,
      launch_browser_ = FALSE,
      docker_run_server_ = docker_run_server
    ),
    supervise = TRUE,
    stdout = "|",
    stderr = "2>&1",
    cmdargs = c(
      "--slave", # tell the session that it's being controlled by something else
      # "--interactive", # (UNIX only) # tell the session that it's interactive.... but it's not
      "--quiet", # no printing
      "--no-save", # don't save when done
      "--no-restore" # don't restore from .RData or .Rhistory
    )
  )
  on.exit({
    if (docker_proc$is_alive()) {
      message("Killing Docker...")
      docker_proc$kill()
      docker_stop(type, r_version, release)
      message("Killing Docker... OK")
    }
  }, add = TRUE)

  # wait for docker to start
  ## (wait until '/' is available)
  get_docker_output <- function() {
    if (!docker_proc$is_alive()) {
      return("")
    }
    out <- docker_proc$read_output_lines()
    if (length(out) > 0 && nchar(out) > 0) {
      paste0(out, collapse = "\n")
    } else {
      ""
    }
  }
  while (TRUE) {
    if (!docker_proc$is_alive()) {
      message("Trying to display docker failure message...")
      print(docker_proc$read_all_output_lines())
      stop("Background docker process has errored.")
    }
    tryCatch({
      # will throw error on connection failure
      message("Waiting for url to respond:", "http://127.0.0.1:", port_background)
      httr::GET(paste0("http://127.0.0.1:", port_background))
      cat(get_docker_output(), "\n")
      break
    }, error = function(e) {
    message("error", e)
      Sys.sleep(0.5) # arbitrary, but it'll be a while till the docker is launched
      # display all docker output
      out <- get_docker_output()
      if (nchar(out) > 0) {
        cat(out, "\n", sep = "")
      }
      invisible()
    })
  }
  cat("(Docker output will no longer be tracked in console)\n")
  message("Starting Docker... OK") # starting docker

  output_lines <- ""
  app_infos <- lapply(apps, function(app_name) {
    list(
      app_name = app_name,
      start = function() {
        output_lines <<- ""
        invisible(TRUE)
      },
      on_session_ended = function() { invisible(TRUE) },
      output_lines = function(reset = FALSE) {
        if (release == "centos7") {
          return("(centos7 console output not available)")
        }
        if (isTRUE(reset)) {
          output_lines <<- ""
          return(output_lines)
        }
        if (is.null(docker_proc) || !docker_proc$is_alive()) {
          return("(dead)")
        }
        docker_proc_output_lines <- docker_proc$read_output_lines()
        if (any(nchar(docker_proc_output_lines) > 0)) {
          output_lines <<- paste0(
            output_lines,
            if (nchar(output_lines) > 0) "\n",
            paste0(docker_proc_output_lines, collapse = "\n")
          )
        }
        output_lines
      },
      app_url = function() {
        paste0("http://", host, ":", port_background, "/", app_name)
      },
      # user_agent = function(user_agent) {
      #   app_status_user_agent_browser(user_agent, paste0(type, "_", r_version, "_", release))
      # },
      header = function() {
        shiny::tagList(shiny::tags$strong(type, ": "), shiny::tags$code(release), ", ", shiny::tags$code(paste0("r", r_version)))
      }
    )
  })

  test_in_external(
    app_infos = app_infos,
    default_app_name = resolve_app_name(app_name),
    host = host,
    port = port
  )
}

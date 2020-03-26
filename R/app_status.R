
# log files
# app pass/fail/unknown (no file)


# in status folder
# ./_version_info.json
# * folder api version
# * all identifiying string in parent folder
# (check if apps repo is up to date)
# (check if apps repo is on master)

# ./APPNAME/_latest.json
# ./APPNAME/TIME.json
# * shinycoreci sha used
# * apps sha
# * pass / fail
# * log information


app_status_version <- 1
app_status_folder_name <- "test_status"
app_status_version_info_name <- "_version_info.json"
app_status_latest_name <- "_latest.json"


#' Testing status
#'
#' @param dir base folder containing all shiny apps
#' @param apps names of all shiny applications
#' @describeIn app_status Retrieve status of all manual executions
#' @export
#' @examples
#' \dontrun{app_status()}
app_status <- function(dir = "apps", apps = basename(apps_manual(dir))) {
  statuses <- lapply(dir(file.path(dirname(dir), app_status_folder_name), full.names = TRUE), function(status_folder) {
    app_status_info(dir = dir, apps = apps, status_folder = status_folder)
  })

  ret <- list(
    statuses = statuses
  )

  class(ret) <- c("shinycoreci_app_status", "list")
  ret
}


# should return a data.frame of information
# * app (name)
# * successful
# * R version
# * browser
#   * chrome
#   * firefox
#   * ie
#   * edge
#   * safari
#   * rstudio_v1_2
#   * else the full User-Agent value
# * list(log outputs)
# should have a custom print method display pass/total count and possible failures plus  maybe a couple logs
app_status_info <- function(dir = "apps", apps = basename(apps_manual(dir)), status_folder = file.path(dirname(dir), app_status_folder(user_agent = user_agent)), user_agent = NULL) {
  app_folders <- dir(status_folder, full.names = TRUE)
  contents <- lapply(app_folders, function(app_folder) {
    read_path <- file.path(app_folder, app_status_latest_name)
    if (!file.exists(read_path)) return(NULL)

    as.data.frame(
      jsonlite::read_json(read_path),
      stringsAsFactors = FALSE
    )
  })

  status <- do.call(rbind, contents)
  total_apps <- length(apps)
  completed <- sum(basename(apps) %in% basename(app_folders))


  ret <- list(
    status_folder = status_folder,
    dir = dir,
    apps = apps,
    info = jsonlite::read_json(file.path(status_folder, app_status_version_info_name)),
    stats = list(
      total = total_apps,
      passing = sum(status$pass),
      failing = sum(!status$pass),
      completed = completed
    ),
    status = status # should be last
  )
  class(ret) <- c("shinycoreci_app_status_info", "list")
  ret
}
#' @export
print.shinycoreci_app_status_info <- function(x, ...) {
  if (x$stats$passing == x$stats$total) {
    cat("# ", basename(x$status_folder), " √\n", sep = "")
    return()
  } else {
    cat("# ", basename(x$status_folder), "\n", sep = "")
  }


  pad_num <- function(y) {
    pad_left(as.character(y), " ", nchar(as.character(x$stats$total)))
  }
  trim_apps <- function(apps) {
    app_txt <- paste0(apps, collapse = ", ")
    if (nchar(app_txt) > 100) {
      app_txt <- paste0(substr(app_txt, 0, 100 - 3), "...")
    }
    app_txt
  }


  if (x$stats$passing > 0) {
    cat("√ Pass: ", pad_num(x$stats$passing), " / ", x$stats$total, "\n", sep = "")
  }
  if (x$stats$completed < x$stats$total) {
    cat(
      "* TODO: ", pad_num(x$stats$total - x$stats$completed), " / ", x$stats$total, " ",
      trim_apps(basename(x$apps)[! (basename(x$apps) %in% basename(x$status$app))]),
      "\n",
      sep = ""
    )
  }
  if (x$stats$failing > 0) {
    cat(
      "! Fail: ", pad_num(x$stats$failing), " / ", x$stats$total, " ",
      trim_apps(basename(x$status$app)[!x$status$pass]),
      "\n",
      sep = ""
    )
    # cat("! Failing log from App: ", x$status$app[!x$status$pass][1], "\n", sep = "")
    for (i in 1:3) {
      if (x$stats$failing < i) break
      cat("<< ", x$status$app[!x$status$pass][i], " <<<<<<<<<<<<<<<\n", sep = "")
      cat(x$status$log[!x$status$pass][i], "\n", sep = "")
      cat(">> ", x$status$app[!x$status$pass][i], " >>>>>>>>>>>>>>>\n", sep = "")
    }
  }

  # str(x$status)
}
#' @export
print.shinycoreci_app_status <- function(x, ...) {
  lapply(x$statuses, function(status) {
    print(status)
    cat("\n")
  })

  count <- 0
  total_count <- sum(vapply(x$statuses, function(y) y$stats$total, numeric(1)))
  total_passing <- sum(vapply(x$statuses, function(y) y$stats$passing, numeric(1)))
  pad_num <- function(y) {
    pad_left(as.character(y), " ", nchar(as.character(total_count)))
  }
  cat("Passing: ", pad_num(total_passing), " / ", pad_num(total_count), "\n", sep = "")
  lapply(x$statuses, function(status_info) {
    cat("* ", pad_num(status_info$stats$passing), " / ", pad_num(status_info$stats$total), " - ", basename(status_info$status_folder), "\n", sep = "")
  })
  # cat("-----------------------\n", "  ", pad_num(count), " / ", pad_num(total_count), "\n", sep = "")
}

#' @export
#' @describeIn app_status Display the google sheet status to be submitted
app_status_sheet <- function(dir = "apps", apps = basename(apps_manual(dir)), status = app_status(dir = dir, apps = apps)) {
  ans <- utils::menu(
    choices = vapply(status$statuses, function(x) basename(x$status_folder), character(1)),
    graphics = FALSE,
    title = "Which status would you like to print?"
  )

  status_item <- status$statuses[[ans]]
  str(status_item)
  status_dt <- status_item$status
  status_dt
  merged_dt <- merge(
    data.frame(
      app = status_item$apps,
      stringsAsFactors = FALSE
    ),
    status_dt[, c("app", "pass", "log")],
    all.x = TRUE
  )

  cat("------------------\n")
  for (i in seq_len(nrow(merged_dt))) {
    to_print <- switch(
      as.character(merged_dt$pass[i]),
      "TRUE" = "1",
      "FALSE" = paste0("Failure: ", merged_dt$log[i]),
      ""
    )
    cat(to_print, "\n")
  }
  cat("------------------\n")
  cat("Copy the text above into the testing sheet")
}



app_status_init <- function(
  dir,
  user_agent,
  verify = TRUE
) {
  app_status_folder_save(user_agent)

  app_status_validate_app_branch(dir)
  app_status_validate_shinycoreci_branch()
}

# return folder for status info
app_status_folder <- function(
  user_agent
) {
  file.path(
    app_status_folder_name,
    paste(
      sep = "_",
      platform(),
      app_status_r_version(),
      app_status_browser(user_agent)
    )
  )
}
# return folder for app
app_status_folder_app <- function(
  app,
  user_agent
) {
  file.path(
    dirname(dirname(app)),
    app_status_folder(user_agent),
    basename(app)
  )
}
# make sure folder is created
app_status_folder_create <- function(folder) {
  if (!dir.exists(folder)) {
    dir.create(folder, recursive = TRUE)
  }
  invisible(folder)
}
# save all information in base status folder
app_status_folder_save <- function(user_agent) {
  save_file <- file.path(app_status_folder(user_agent = user_agent), app_status_version_info_name)
  # * folder api version
  # * all identifiying string in parent folder
  info <- list(
    version = app_status_version,
    user_agent = user_agent,
    r = app_status_r_version(),
    platform = platform(),
    browser = app_status_browser(user_agent = user_agent)
  )

  app_status_write_json(info, save_file)
}
app_status_r_version <- function() {
  paste0("r", R.Version()$major, sub("\\.", "", R.Version()$minor))
}

app_status_write_json <- function(x, file) {
  app_status_folder_create(dirname(file))
  jsonlite::write_json(x, file, auto_unbox = TRUE, pretty = TRUE)
  invisible(x)
}


app_status_save <- function(
  app_dir, # full app directory
  pass, # TRUE/FALSE
  log,
  user_agent
) {
  info <- list(
    app_dir = dirname(app_dir),
    app = basename(app_dir),
    pass = isTRUE(pass),
    time = Sys.time(),
    apps_sha = app_status_app_sha(dirname(app_dir)),
    shinycoreci_sha = app_status_shinycoreci_sha(),
    log = log # should go last
  )

  status_folder <- app_status_folder_app(app_dir, user_agent)
  app_status_write_json(info, file.path(status_folder, app_status_latest_name))
  app_status_write_json(info, file.path(status_folder, paste0(gsub("[^a-zA-Z0-9-]", "_", as.character(Sys.time())), ".json")))
  invisible(status_folder)
}

# get the apps short sha
app_status_app_sha <- function(
  dir
) {
  dir <- normalizePath(dir)

  run_system_cmd(
    "cd '", dir, "' && ",
    "git rev-parse --short HEAD"
  )
}
# get the shinycoreci short sha
app_status_shinycoreci_sha <- function() {
  if (shinycoreci_is_loaded_with_devtools()) {
    return("(local)")
  }

  substr(
    remotes__load_pkg_description(system.file(package = "shinycoreci"))$remotesha,
    0, 7
  )
}

app_status_validate_app_branch <- function(dir) {
  dir <- normalizePath(dir)
  apps_branch <- run_system_cmd(
    "cd '", dir, "' && ",
    "git rev-parse --abbrev-ref HEAD"
  )
  if (!identical(apps_branch, "master")) {
    if (
      !ask_yes_no("'apps' branch is currently: '", apps_branch, "'. Is this ok?")
    ) {
      stop("Change 'apps' branch to `master`")
    }
  }
  invisible(TRUE)
}
app_status_validate_shinycoreci_branch <- function() {
  if (shinycoreci_is_loaded_with_devtools()) {
    return()
  }

  ref <- remotes__load_pkg_description(system.file(package = "shinycoreci"))$remoteref
  if (!identical(ref, "master")) {
    if (
      !ask_yes_no("'shinycoreci' branch is currently: '", ref, "'. Is this ok?")
    ) {
      stop("Change 'shinycoreci' branch to `master`. `remotes::install_github(\"rstudio/shinycoreci\")`")
    }
  }
  invisible(TRUE)
}

# app_status_os <- function() {
#   platform()
# }
app_status_browser <- function(user_agent) {

  rstudio_version <- function() {
    paste0(
      "rstudio_",
      gsub("[^0-9]", "_", rstudioapi::versionInfo()$version, fixed = TRUE)
    )
  }

  if (rstudioapi::isAvailable("1.3.387")) {
    viewer_type <- rstudioapi::readRStudioPreference("shiny_viewer_type", "not-correct")
    if (!identical(viewer_type, "browser")) {
      return(rstudio_version())
    }
    # if browser, continue like a regular app
  } else if (rstudioapi::isAvailable()) {
    runExternal <- get(".rs.invokeShinyWindowExternal", envir = as.environment("tools:rstudio"))
    if (!identical(
      getOption("shiny.launch.browser", "not-correct"),
      runExternal
    )) {
      return(rstudio_version())
    }
    # if browser, continue like a regular app
  }

  ## Windows 10-based PC using Edge browser
  # Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246
  ## Chrome OS-based laptop using Chrome browser (Chromebook)
  # Mozilla/5.0 (X11; CrOS x86_64 8172.45.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.64 Safari/537.36
  ## Mac OS X-based computer using a Safari browser
  # Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Safari/601.3.9
  ## Windows 7-based PC using a Chrome browser
  # Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.111 Safari/537.36
  ## Linux-based PC using a Firefox browser
  # Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:15.0) Gecko/20100101 Firefox/15.0.1
  ## IE 11
  # Mozilla/5.0 (Windows NT 6.3; WOW64; Trident/7.0; rv:11.0) like Gecko

  if (grepl("Edge/", user_agent)) return("edge")
  if (grepl("Firefox/", user_agent)) return("firefox")
  if (grepl("Trident/", user_agent)) return("ie")
  if (grepl("Safari/", user_agent)) return("safari")
  if (grepl("Chrome/", user_agent)) return("chrome")

  ret <- gsub("[^a-z0-9]", "_", tolower(user_agent))

  message("Found unknown user agent string: ", user_agent)
  message("Storing: ", ret)

  ret
}

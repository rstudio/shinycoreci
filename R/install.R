is_installed <- function(package) {
  nzchar(system.file(package = package))
}
check_installed <- function(package) {
  if (!is_installed(package)) {
    stop(package, " is not installed and is required by `shinycoreci`")
  }
}



shinyverse_remotes <- c(
  "r-lib/cachem",
  "r-lib/fastmap",
  "r-lib/later",
  "rstudio/bslib",
  "rstudio/crosstalk",
  "rstudio/DT",
  "rstudio/dygraphs",
  "rstudio/flexdashboard",
  "rstudio/fontawesome",
  "rstudio/htmltools",
  "rstudio/httpuv",
  "rstudio/pool",
  "rstudio/promises",
  "rstudio/reactlog",
  "rstudio/rsconnect",
  "rstudio/sass",
  "rstudio/shiny",
  "rstudio/shinymeta",
  "rstudio/shinytest",
  "rstudio/shinytest2",
  "rstudio/shinythemes",
  "rstudio/shinyvalidate",
  "rstudio/thematic",
  "rstudio/webdriver",
  "rstudio/websocket",
  "schloerke/shinyjster",
  NULL
)
shinyverse_pkgs <- vapply(strsplit(shinyverse_remotes, "/"), `[[`, character(1), 2)

shinycoreci_is_local <- function() {
  # If `.git` folder exists, we can guess it is in dev mode
  dir.exists(
    file.path(
      dirname(system.file("DESCRIPTION", package = "shinycoreci")),
      ".git"
    )
  )
}


# Used in GHA workflow
install_shinyverse_local <- function(
  ...,
  # Install into normal libpath so caching is automatically handled
  libpath = .libPaths()[1]
) {
  install_shinyverse(..., libpath = libpath)
}

#' @noRd
#' @return lib path being used
install_shinyverse <- function(
  install = TRUE,
  validate_loaded = TRUE,
  extra_packages = NULL,
  libpath = shinyverse_libpath()
) {
  if (!isTRUE(install)) return(.libPaths()[1])

  # Make sure none of the shinyverse is loaded into namespace
  if (isTRUE(validate_loaded)) {
    shiny_search <- paste0("package:", shinyverse_pkgs)
    if (any(shiny_search %in% search())) {
      bad_namespaces <- shinyverse_pkgs[shiny_search %in% search()]
      stop(
        "The following packages are already loaded:\n",
        paste0("* ", bad_namespaces, "\n", collapse = ""),
        "Please restart and try again"
      )
    }
  }

  # Remove shinyverse
  apps_deps <- apps_deps[!(apps_deps %in% c(shinyverse_pkgs, "shinycoreci", "shinycoreciapps"))]
  pak_apps_deps <- paste0("any::", apps_deps)

  # Load pak into current namespace
  pkgs <- c(shinyverse_remotes, pak_apps_deps, extra_packages)
  message("Installing shinyverse and app deps: ", libpath)
  if (!is.null(extra_packages)) {
    message("Extra packages:\n", paste0("* ", extra_packages, collapse = "\n"))
  }
  callr::r(
    function(pkgs, lib) {
      # Performing a leap of faith that pak is installed.
      # Avoids weird installs when using pak to install shinycoreci
      stopifnot(utils::packageVersion("pak") >= "0.3.0")
      pak::pkg_install(
        pkgs,
        lib = lib,
        upgrade = TRUE,
        ask = FALSE,
        dependencies = TRUE
      )
    },
    list(
      pkgs = pkgs,
      lib = libpath
    ),
    show = TRUE,
    spinner = TRUE # helps with CI from timing out
  )

  return(libpath)
}

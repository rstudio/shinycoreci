# Run by calling `source("inst/gha/install-shinyverse.R")` in the terminal

# Performing a leap of faith that pak is installed.
# Avoids weird installs when using pak to install shinycoreci
stopifnot(utils::packageVersion("pak") >= "0.3.0")

install_pkgs <- function(pkgs) {
  lapply(pkgs, function(pkg) {
    if (require(pkg, quietly = TRUE, character.only = TRUE)) return()

    pak::pkg_install(pkg)
  })
}

ignore <- install_pkgs(c("withr", "renv"))

if (!require("renv", quietly = TRUE, character.only = TRUE)) {
  pak::pak("renv", ask = FALSE)
}

# Source install files and data
for (file in c("R/data-shinyverse.R", "R/install-path.R", "R/install.R")) {
  message("Sourcing: ", file)
  if (!file.exists(file)) {
    stop("File does not exist: ", file)
  }
  path_pkg_deps <- unique(renv::dependencies(file, quiet = TRUE)$Package)
  install_pkgs(path_pkg_deps)

  source(file, local = FALSE)
}

attempt_to_install_universe(libpath = resolve_libpath())


# withr::with_options(
#   list(
#     repos = c(
#       # Use the shinycoreci universe to avoid GH rate limits!
#       "AAA" = "https://posit-dev-shinycoreci.r-universe.dev",
#       getOption("repos", c("CRAN" = "https://cloud.r-project.org"))
#     )
#   ),
#   {
#     message("Installing shinyverse: ", paste0(shinyverse_pkgs, collapse = ", "))
#     message("libpath: ", shinycoreci_libpath())
#     message("options()$repos:")
#     str(getOption("repos"))
#     pak::pkg_install(
#       shinyverse_pkgs,
#       lib = shinycoreci_libpath(),
#       ask = TRUE, # Not interactive, so don't ask
#     )
#   }
# )

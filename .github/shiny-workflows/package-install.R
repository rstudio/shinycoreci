is_linux   <- function() Sys.info()[["sysname"]] == "Linux"


install_troublesome_pkgs <- function(pkgs) {
  if (!requireNamespace("pak")) {
    install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch))
  }

  # Always install system deps
  pak::pkg_system_requirements(pkgs, execute = TRUE)

  # Install missing pkgs
  installed_packages <- as.data.frame(installed.packages(), stringsAsFactors = FALSE)$Package
  pkgs_to_install <- pkgs[!(pkgs %in% installed_packages)]
  if (length(pkgs_to_install) > 0) {
    message("Installing packages: ", paste0(pkgs_to_install, collapse = ", "))
    install.packages(pkgs_to_install)
  }
}

if (is_linux()) {
  switch(as.character(getRversion()),
    "3.6.3" = {
      install_troublesome_pkgs(c("rjson"))
    },
    "3.5.3" = {
      install_troublesome_pkgs(c("rjson", "radiant"))
      # These packages do not like to be installed on earlier R versions
    },
    {
      if (grepl("^4\\.2", getRversion())) {
        install_troublesome_pkgs(c("XML"))
      }
    }
  )
}

is_linux   <- function() Sys.info()[["sysname"]] == "Linux"


install_troublesome_pkgs <- function(pkg_infos) {
  if (!requireNamespace("pak")) {
    install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch))
  }

  # Install missing pkgs
  installed_packages <- as.data.frame(installed.packages(), stringsAsFactors = FALSE)$Package
  for (pkg_info in pkg_infos) {
    pkg_name <- pkg_info$name
    pkg_version <- pkg_info$version
    if (!(pkg_name %in% installed_packages)) {
      message("Installing package: ", pkg_name)
      pak::pkg_system_requirements(pkg_name, execute = TRUE)
      if (is.null(pkg_version)) {
        install.packages(pkg_name)
      } else {
        if (!requireNamespace("remotes")) {
          install.packages("remotes")
        }
        remotes::install_version(pkg_name, pkg_version)
      }
    }
  }
}

if (is_linux()) {
  switch(as.character(getRversion()),
    "3.6.3" = {
      install_troublesome_pkgs(
        list(
          list(name = "rjson", version = "0.2.20")
        )
      )
    },
    "3.5.3" = {
      install_troublesome_pkgs(
        list(
          list(name = "rjson", version = "0.2.20"),
          list(name = "radiant", version = "1.3.2")
        )
      )
      # These packages do not like to be installed on earlier R versions
    },
    {
      if (grepl("^4\\.2", getRversion())) {
        install_troublesome_pkgs(
          list(
            list(name = "XML", version = NULL)
          )
        )
      }
    }
  )
}

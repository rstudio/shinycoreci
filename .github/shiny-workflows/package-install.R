is_linux   <- function() Sys.info()[["sysname"]] == "Linux"

install_troublesome_pkgs <- function(pkgs) {
  pak::system_requirements(pkgs, execute = TRUE)
  installed_packages <- as.data.frame(installed.packages(), stringsAsFactors = FALSE)$Package
  pkgs_to_install <- pkgs[!(pkgs %in% installed_packages)]
  if (length(pkgs_to_install) > 0) {
    install.packages(pkgs_to_install)
  }

}

if (is_linux()) {
  cur_r_version <- paste0(R.version$major, ".", R.version$minor)
  switch(cur_r_version,
    "3.6.3" = {
      install_troublesome_pkgs(c("rjson"))
    },
    "3.5.3" = {
      install_troublesome_pkgs(c("rjson", "radiant"))
      # These packages do not like to be installed on earlier R versions
    }
  )

  if (grepl("^4\\.2", cur_r_version)) {
    install_troublesome_pkgs(c("XML"))
  }
}

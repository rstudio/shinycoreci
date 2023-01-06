adjust_pkgs <- function(pkgs_to_install = "rstudio/shiny,rstudio/bslib", r_version = "4.2.1") {
  is_windows <- .Platform$OS.type == "windows"
  is_linux <- Sys.info()[["sysname"]] == "Linux"
  is_mac <- Sys.info()[["sysname"]] == "Darwin"
  # Get R version like `"4.2"`
  short_r_version <- sub("\\.\\d$", "", r_version)

  replace_or_add <- function(find_val, replace_val) {
    pkgs_to_install <<-
      if (grepl(find_val, pkgs_to_install, fixed = TRUE)) {
        sub(find_val, replace_val, pkgs_to_install, fixed = TRUE)
      } else {
        paste0(pkgs_to_install, ",", replace_val)
      }
  }

  if (is_mac) {
    switch(short_r_version,
      "3.5" = {
        # Apps 181-185
        replace_or_add(
          "any::systemfonts",
          "url::https://cran.r-project.org/src/contrib/Archive/systemfonts/systemfonts_1.0.3.tar.gz"
        )
      }
    )
  }
  if (is_linux) {
    switch(short_r_version,
      "4.2" = {
        replace_or_add("any::XML", "XML")
      },
      "3.6" = {
        replace_or_add(
          "any::rjson",
          "url::https://cran.r-project.org/src/contrib/Archive/rjson/rjson_0.2.20.tar.gz"
        )
      },
      "3.5" = {
        replace_or_add(
          "any::rjson",
          "url::https://cran.r-project.org/src/contrib/Archive/rjson/rjson_0.2.20.tar.gz"
        )
        replace_or_add(
          "any::radiant",
          "url::https://cran.r-project.org/src/contrib/Archive/radiant/radiant_1.3.2.tar.gz"
        )
        replace_or_add(
          "any::pdp",
          "url::https://cran.r-project.org/src/contrib/Archive/pdp/pdp_0.7.0.tar.gz"
        )
        replace_or_add(
          "any::RcppEigen",
          "url::https://cran.r-project.org/src/contrib/Archive/RcppEigen/RcppEigen_0.3.3.9.2.tar.gz"
        )
        replace_or_add(
          "any::MatrixModels",
          "url::https://cran.r-project.org/src/contrib/Archive/MatrixModels/MatrixModels_0.5-0.tar.gz"
        )
      }
    )
  }
  if (is_windows) {
    switch(short_r_version,
      "3.5" = {
        replace_or_add(
          "any::mapview",
          "url::https://cran.r-project.org/bin/windows/contrib/3.5/mapview_2.7.8.zip"
        )
        replace_or_add(
          "any::sf",
          "url::https://cran.r-project.org/bin/windows/contrib/3.5/sf_0.9-2.zip"
        )

        # https://github.com/r-spatial/s2/issues/140
        # Once s2 > 1.0.7 is released, this can be removed... hopefully
        replace_or_add(
          "any::s2",
          "r-spatial/s2"
        )
      }
    )
  }
  pkgs_to_install
}

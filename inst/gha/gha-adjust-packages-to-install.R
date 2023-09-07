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
      }
    )
  }
  pkgs_to_install
}

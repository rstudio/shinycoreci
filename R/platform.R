
is_windows <- function() .Platform$OS.type == "windows"
is_mac     <- function() Sys.info()[["sysname"]] == "Darwin"
is_linux   <- function() Sys.info()[["sysname"]] == "Linux"

#' Execution platform
#' @return one of `c("win", "mac", "linux")`
#' @export
platform <- function() {
  if (is_windows()) return("win")
  if (is_mac())     return("mac")
  if (is_linux())   return("linux")
  stop("unknown platform")
}

#' R Version
#' @return Major and minor number only. Ex: `"4.0"`
#' @export
r_version_short <- function() {
  paste0(R.Version()$major,".",strsplit(R.Version()$minor, ".", fixed = TRUE)[[1]][1])
}

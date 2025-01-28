#' Write system information to a file
#'
#' @param file Name of file, or file object to write to (defaults to stdout).
#' @param libpath Library path to find installed packages.
#' @export
write_sysinfo <- function(file = stdout(), libpath = resolve_libpath()) {
  withr::local_libpaths(libpath, action = "prefix")

  platform_info <- sessioninfo::platform_info()
  platform_info_cls <- class(platform_info)
  # Shim in the GitHub Actions image version
  platform_info <- c(gha_image = gha_image_version(), platform_info)
  class(platform_info) <- platform_info_cls

  pkg_info <- sessioninfo::package_info("installed", include_base = FALSE)

  cat(
    if (rlang::is_installed("chromote", version = "0.4.0")) {
      c(
        format(cli::rule("Chrome Info")),
        capture.output(print(chromote::chromote_info()))
      )
    } else {
      "{chromote} v0.4.0 or later is not installed."
    },
    format(cli::rule("Session info")),
    format(platform_info),
    format(cli::rule("Packages")),
    format(pkg_info),
    sep = "\n",
    file = file
  )
}

gha_image_version <- function() {
  Sys.getenv("ImageVersion", "($ImageVersion not found)")
}

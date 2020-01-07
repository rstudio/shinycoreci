#' Find package dependencies used in a directory
#'
#' @param dir The directory to look in.
#'
#' @export
find_deps_installed <- function(dir = ".") {
  deps <- triple_colon("renv", "renv_snapshot_r_packages")(.libPaths(), normalizePath(dir))
  cols <- c(
    "Package",
    "Version",
    "Source",
    "Repository",
    "RemoteSha",
    "RemoteUsername",
    "RemoteRef"
  )
  df <- d3_to_df(deps, cols)

  # Massage the data frame into something that prints nicely.
  rownames(df) <- NULL
  repo_idx <- df$Source == "Repository"
  df$Source[repo_idx] <- df$Repository[repo_idx]
  df$RemoteUsername[repo_idx| is.na(df$RemoteUsername)] <- ""
  df$RemoteSha[repo_idx | is.na(df$RemoteSha)] <- ""
  df$RemoteRef[repo_idx | is.na(df$RemoteRef)] <- ""
  df$Ref <- paste(df$RemoteUsername, df$RemoteRef, sep = "/")
  df$Ref[df$Ref == "/"] <- ""
  df$RemoteSha <- substr(df$RemoteSha, 1, 7)
  names(df)[names(df) == "RemoteSha"] <- "SHA"

  df$Repository <- NULL
  df$RemoteUsername <- NULL
  df$RemoteRef <- NULL

  df
}

#' Write system information to a file
#'
#' @param file Name of file, or file obect to write to (defaults to stdout).
#' @export
write_sysinfo <- function(file = stdout()) {
  opts <- options()
  on.exit(options(opts))
  options(width = 1000)

  cat(
    utils::capture.output({
      print(sessioninfo::platform_info())
      cat(rep("-", 80), "\n", sep = "")
      print(find_deps_installed(), max = 10000)
    }),
    sep = "\n",
    file = file
  )
}

#' Return names of packages included with R
#'
#' Some installed packages have a Priority of "base" or "recommended".
#' Shouldn't try to upgrade these packages with \code{remotes::install_cran}
#' because it will fail.
#' @export
base_packages <- function() {
  pkg_df <- as.data.frame(utils::installed.packages(), stringsAsFactors = FALSE)
  pkg_df$Package[pkg_df$Priority %in% c("base", "recommended")]
}

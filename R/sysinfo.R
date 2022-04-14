#' Find package dependencies installed
#'
# ' @export
find_deps_installed <- function() {
  deps <- renv__renv_snapshot_r_packages(c(shinyverse_libpath(), .libPaths()))
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
#' @param file Name of file, or file object to write to (defaults to stdout).
#' @export
write_sysinfo <- function(file = stdout()) {
  check_installed("sessioninfo")

  opts <- options()
  on.exit(options(opts))
  options(width = 1000)

  cat(
    utils::capture.output({
      cat("Image Version: ", gha_image_version(), "\n")
      cat("osVersion: ", utils::sessionInfo()$running, "\n", sep = "")
      cat(rep("-", 80), "\n", sep = "")
      print(sessioninfo::platform_info())
      cat(rep("-", 80), "\n", sep = "")
      print(find_deps_installed(), max = 10000)
    }),
    sep = "\n",
    file = file
  )
}


gha_image_version <- function() {
  Sys.getenv("ImageVersion", "($ImageVersion not found)")
}

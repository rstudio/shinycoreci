if (!requireNamespace("digest", quietly = TRUE)) {
  # Need for url remotes. See https://github.com/r-lib/actions/issues/562#issuecomment-1129088041
  install.packages("digest", repos = "http://cran.us.r-project.org")
}

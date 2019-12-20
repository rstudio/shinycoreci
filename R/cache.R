# This cache is used for test chart data and package information.
cache <- new.env()

#' Clear cache for test chart and package info
#'
#' @export
clear_cache <- function() {
  names <- ls(cache, all.names = TRUE)
  rm(list = names, envir = cache)
}

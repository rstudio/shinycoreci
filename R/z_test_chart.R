# This cache is used for test chart data and package information.
cache <- new.env()

#' Clear cache for test chart and package info
#'
# ' @export
clear_cache <- function() {
  names <- ls(cache, all.names = TRUE)
  rm(list = names, envir = cache)
}

# Fetch spreadsheet with app testing information. Result is memoized. Use
# `reset=TRUE` to clear cache.
get_test_chart <- function() {
  if (!is.null(cache$last_result)) {
    return(cache$last_result)
  }

  sheet_id <- "1jPWPNmSQbbE8E6KS5tXnm5Jq7r01GaOCCE1Vvz5e9a8"
  sheet_name <- "Sheet1"
  url <- sprintf(
    "https://docs.google.com/spreadsheets/d/%s/gviz/tq?tqx=out:csv&sheet=%s",
    sheet_id,
    sheet_name
  )

  app_data <- utils::read.csv(url, stringsAsFactors = FALSE)
  app_data <- app_data[, c("App", "manual", "shinytest", "shinyjster", "shinytest.done", "shinyjster.done")]

  cache$last_result <- app_data
  app_data
}

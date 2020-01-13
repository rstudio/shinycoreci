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

#' Get names of apps to be tested with shinytest or shinyjster
#'
#' The data is fetched from a Google spreadsheet and cached for the duration
#' of the R session. To reset the cache, call \code{clear_cache()}.
#'
#' @export
apps_shinytest <- function() {
  df <- get_test_chart()
  df$App[df$shinytest.done != ""]
}


#' @rdname apps_shinytest
#' @export
apps_shinyjster <- function() {
  df <- get_test_chart()
  apps <- df$App[df$shinyjster.done != ""]

  if (is_mac()) {
    apps <- setdiff(apps, "174-throttle-debounce")
  } else if (is_windows()) {
    apps <- setdiff(apps, "022-unicode-chinese")
  }

  apps
}

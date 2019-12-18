# Fetch spreadsheet with app testing information
get_test_chart <- function() {
  sheet_id <- "1jPWPNmSQbbE8E6KS5tXnm5Jq7r01GaOCCE1Vvz5e9a8"
  sheet_name <- "Sheet1"
  url <- sprintf(
    "https://docs.google.com/spreadsheets/d/%s/gviz/tq?tqx=out:csv&sheet=%s",
    sheet_id,
    sheet_name
  )

  app_data <- utils::read.csv(url, stringsAsFactors = FALSE)
  app_data <- app_data[, c("App", "manual", "shinytest", "shinyjster", "shinytest.done", "shinyjster.done")]
  app_data
}


#' Get names of apps to be tested with shinytest
#' @export
apps_shinytest <- function() {
  df <- get_test_chart()
  df$App[df$shinytest.done != ""]
}


#' Get names of apps to be tested with shinyjster
#' @export
apps_shinyjster <- function() {
  df <- get_test_chart()
  df$App[df$shinyjster.done != ""]
}

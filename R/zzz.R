`%>%` <- NULL

.onLoad <- function(...) {
  `%>%` <<- dplyr::`%>%`

  apps_on_load()
}

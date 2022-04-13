library(shinyjster)

test_jster_169 <- function(browser_func) {

  app <- "../"

  # delete cache file
  cache_file <- file.path(app, "169-prerender-a", "index.html")
  if (file.exists(cache_file)) {
    unlink(cache_file)
  }
  on.exit({
    if (file.exists(cache_file)) {
      unlink(cache_file)
    }
  }, add = TRUE)

  shinyjster::test_jster(
    apps = c(
      file.path(app, "169-prerender-a", "index.Rmd"),
      file.path(app, "169-prerender-b")
    ),
    type = "lapply",
    browsers = browser_func
  )
}

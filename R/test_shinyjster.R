shinyjster_apps_to_test <- function() {
  file.path("apps", c(
    "002-hello-jster",
    if (!is_windows()) "022-unicode-chinese",
    "025-loop-ui",
    "121-async-timer",
    "122-async-outputs",
    "123-async-renderprint",
    "124-async-download",
    "125-async-req",
    "126-async-ticks",
    "128-plot-dim-error",
    "129-async-perf",
    "130-output-null",
    "131-renderplot-args",
    "133-async-hold-inputs",
    "134-async-hold-timers",
    "140-selectize-inputs",
    "143-async-plot-caching",
    "145-dt-replacedata",
    "168-dynamic-hosted-tab"
  ))
}


#' Test shinyjster
#'
#' @inheritParams shinyjster::run_headless
#' @export
test_shinyjster <- function(
  apps = shinyjster_apps_to_test(),
  port = 8000,
  host = "127.0.0.1",
  debug_port = NULL,
  browser = c("chrome", "firefox"),
  type = c("lapply", "parallel", "callr"),
  assert = TRUE
) {
  shinyjster::run_headless(
    apps = apps,
    port = port,
    host = host,
    debug_port = debug_port,
    browser = match.arg(browser),
    type = match.arg(type),
    assert = assert
  )
}

test_that("truncate_log leaves short logs untouched", {
  expect_identical(truncate_log("short log"), "short log")
  expect_identical(truncate_log(c("a", "b")), "a\nb")
})

test_that("truncate_log bounds long logs while keeping head and tail", {
  log <- paste0(strrep("h", 1000), strrep("m", 50000), strrep("t", 1000))
  out <- truncate_log(log)

  expect_lt(nchar(out), 3000)
  expect_match(out, "truncated")
  expect_match(out, "^hhhh")
  expect_match(out, "tttt$")
})

test_that("assert_test_output limits the size of emitted failure logs", {
  big_log <- strrep("x", 10000)
  n <- 10
  test_dt <- tibble::tibble(
    app_name = c("000-pass", sprintf("%03d-app", seq_len(n))),
    status = c(ci_status$pass, rep(ci_status$fail, n)),
    result = replicate(n + 1L, list()),
    log = c("ok", rep(big_log, n))
  )
  class(test_dt) <- c("shinycoreci_test_output", class(test_dt))

  displayed <- character()
  expect_error(
    withCallingHandlers(
      assert_test_output(test_dt),
      message = function(m) {
        displayed <<- c(displayed, conditionMessage(m))
        invokeRestart("muffleMessage")
      }
    ),
    "Failures detected in"
  )
  expect_lt(sum(nchar(displayed, type = "bytes")), 30000)
  expect_true(any(grepl("truncated", displayed, fixed = TRUE)))
})

test_that("a passing app cannot hide an app that could not be tested", {
  for (status in c(ci_status$no_install, ci_status$did_not_return_result)) {
    test_dt <- tibble::tibble(
      app_name = c("000-pass", "001-incomplete"),
      status = c(ci_status$pass, status),
      log = c("ok", "failed to run")
    )
    class(test_dt) <- c("shinycoreci_test_output", class(test_dt))
    expect_error(suppressMessages(assert_test_output(test_dt)), "001-incomplete")
  }
})

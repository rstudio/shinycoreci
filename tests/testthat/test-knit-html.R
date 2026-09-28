test_that("020-knit-html dependencies include litedown", {
  deps <- shinycoreci:::apps_deps_map[["020-knit-html"]]
  expect_true("litedown" %in% deps)
  expect_true("knitr" %in% deps)
  expect_true("rmarkdown" %in% deps)
})

test_that("020-knit-html DESCRIPTION declares litedown dependency", {
  desc_file <- system.file(
    "apps/020-knit-html/DESCRIPTION",
    package = "shinycoreci"
  )
  if (!nzchar(desc_file)) {
    desc_file <- file.path(
      rprojroot::find_package_root_file(),
      "inst/apps/020-knit-html/DESCRIPTION"
    )
  }
  expect_true(file.exists(desc_file))
  desc_content <- readLines(desc_file)
  expect_true(any(grepl("litedown", desc_content)))
})

# Test apps using `shiny::runTests()` using local libpath

Test apps using
[`shiny::runTests()`](https://rdrr.io/pkg/shiny/man/runTests.html) using
local libpath

## Usage

``` r
test_in_local(
  apps = apps_with_tests(repo_dir),
  ...,
  assert = TRUE,
  timeout = 10 * 60,
  retries = 2,
  repo_dir = rprojroot::find_package_root_file(),
  local_pkgs = FALSE
)
```

## Arguments

- apps:

  applications within `dir` to run

- ...:

  ignored

- assert:

  logical value which will determine if
  [`assert_test_output()`](https://rstudio.github.io/shinycoreci/reference/assert_test_output.md)
  will be called on the result

- timeout:

  Length of time allowed for an application's full test suit can run
  before determining it is a failure

- retries:

  number of attempts to retry before declaring the test a failure

- repo_dir:

  Location of local shinycoreci repo

- local_pkgs:

  If `TRUE`, local packages will be used instead of the isolated
  shinyverse installation.

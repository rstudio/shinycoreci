# Actions

Mac installation issues in \<= R 3.6

- Solved in
  <https://github.com/r-lib/pkgdepends/commit/011240b1148e4580895584cc4c5dc5fda7731c97>
  - Waiting for it to naturally resolve.
  - Could use unstable pak, but do not want to as able to test on R \>=
    4.0

Fix installations for R 3.4

- No. R 3.4 will be removed sooner than later

Install using {pac}

Install into lib path

have non shinycoreci pkgs be installed via `any::`

update via flag which is enabled by default

use a separate library for all installations

use this library like revdepcheck does to check packages

double check known namespaces so that they are not carried over from
public library

store the library in the package location given the R version that
persists over installations

Remove `dir` parameter as it should be internally handled

Remove outdated test methods as only testthat is used

- test shinyjster app
- test testthat app
- test shinytest app

Remove app-status stuff. No one uses it

Make action to update renv pkgs with `shinycoreci:::update_apps_deps()`

Run on any update to `inst/internal/apps`

Deploying to Connect should push back connect urls

Port actions from `rstudio/shinycoreci-apps`

Add validation that there is no usage of `shinycoreci::[^:]` in
`./inst/internal/apps`

# Apps

App 217 needs to use
`.Platform$OS.type == "windows" for determining windows support`

Replace all usage of
[`shinycoreci::platform_rversion()`](https://rstudio.github.io/shinycoreci/reference/platform_rversion.md)
with
[`shinytest2::platform_variant()`](https://rstudio.github.io/shinytest2/reference/platform_variant.html)

Replace `shinycoreciapps::testthat_shinyjster()` with
`shinyjster::testthat_shinyjster()`

Convert logic for 169 to use testthat

Move skip logic to inside tests

181-report-image

182-report-png

183-report-cairo

184-report-ragg

193-reactlog-dynamic-ui

301-bs-themes

302-bootswatch-themes

Reduce app name size to have files be under 100bytes

- Fixed by not building test folders. ;-)

# Done

[`deploy_apps()`](https://rstudio.github.io/shinycoreci/reference/deploy_apps.md)

[`view_test_images()`](https://rstudio.github.io/shinycoreci/reference/view_test_images.md)

[`test_in_browser()`](https://rstudio.github.io/shinycoreci/reference/test_in_browser.md)

[`test_in_connect()`](https://rstudio.github.io/shinycoreci/reference/test_in_deployed.md)

[`test_in_shinyappsio()`](https://rstudio.github.io/shinycoreci/reference/test_in_deployed.md)

[`test_in_ide()`](https://rstudio.github.io/shinycoreci/reference/test_in_ide.md)

Test in terminal

`test_in_ci()`

formerly `test_run_tests()`

Changed data structure. Add version

Move `testthat_shinyjster()` to `{shinyjster}` to avoid bad installs

`./docker.R`

## After merge

`fix_all_gha_branches()`

`view_test_diff()`

`view_test_results()`

Remove `test_path` from data structure; Use version to parse old files

Test
[`test_in_ide()`](https://rstudio.github.io/shinycoreci/reference/test_in_ide.md)
in the IDE

test results should be printed to log

[`test_in_sso()`](https://rstudio.github.io/shinycoreci/reference/test_in_ssossp.md)
/
[`test_in_ssp()`](https://rstudio.github.io/shinycoreci/reference/test_in_ssossp.md)

## Docker Notes

Use Rocky Linux 8 instead of centos7


- [x] Mac installation issues in <= R 3.6
  * Solved in https://github.com/r-lib/pkgdepends/commit/011240b1148e4580895584cc4c5dc5fda7731c97
    * Waiting for it to naturally resolve.
    * Could use unstable pak, but do not want to as able to test on R >= 4.0
- [x] Fix installations for R 3.4
  * No. R 3.4 will be removed sooner than later

- [x] Install using {pac}
  - [x] Install into lib path
  - [x] have non shinycoreci pkgs be installed via `any::`
  - [x] update via flag which is enabled by default
  - [x] use a separate library for all installations
    - [x] use this library like revdepcheck does to check packages
    - [x] double check known namespaces so that they are not carried over from public library
    - [x] store the library in the package location given the R version that persists over installations

- [x] Remove `dir` parameter as it should be internally handled

- [x] Remove outdated test methods as only testthat is used
  * test shinyjster app
  * test testthat app
  * test shinytest app

- [x] Remove app-status stuff. No one uses it


# Actions
- [x] Make action to update renv pkgs with `shinycoreci:::update_apps_deps()`
  - [x] Run on any update to `inst/internal/apps`
- [x] Deploying to Connect should push back connect urls
- [x] Port actions from `rstudio/shinycoreci-apps`
- [x] Add validation that there is no usage of `shinycoreci::[^:]` in `./inst/internal/apps`

# Apps
- [x] App 217 needs to use
  `.Platform$OS.type == "windows" for determining windows support`
- [x] Replace all usage of `shinycoreci::platform_rversion()` with `shinytest2::platform_variant()`
- [x] Replace `shinycoreciapps::testthat_shinyjster()` with `shinyjster::testthat_shinyjster()`
- [ ] Convert logic for 169 to use testthat

- [x] Move skip logic to inside tests
  - [x] 181-report-image
  - [x] 182-report-png
  - [x] 183-report-cairo
  - [x] 184-report-ragg
  - [x] 193-reactlog-dynamic-ui
  - [x] 301-bs-themes
  - [x] 302-bootswatch-themes

- [x] Reduce app name size to have files be under 100bytes
  - Fixed by not building test folders. ;-)

# Done
- [x] `deploy_apps()`
- [x] `view_test_images()`
- [x] `test_in_browser()`
- [x] `test_in_connect()`
- [x] `test_in_shinyappsio()`
- [x] `test_in_ide()`
  - [x] Test in terminal

- [x] `test_in_ci()`
  - [x] formerly `test_run_tests()`
  - [x] Changed data structure. Add version

- [x] Move `testthat_shinyjster()` to `{shinyjster}` to avoid bad installs


- [x] `./docker.R`

## After merge
- [ ] `fix_all_gha_branches()`
- [ ] `test_in_sso()` / `test_in_ssp()`
- [ ] `view_test_diff()`
- [ ] `view_test_results()`
- [ ] test results should be printed to log
- [ ] Remove `test_path` from data structure; Use version to parse old files
- [ ] Test `test_in_ide()` in the IDE


## Bad Images
022 - linux chinese is broken

## Docker Notes
Use Rocky Linux 8 instead of centos7

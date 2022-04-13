
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

- [ ] Remove `dir` parameter as it should be internally handled

- [ ] Remove outdated test methods as only testthat is used
  * test shinyjster app
  * test testthat app
  * test shinytest app

- [ ] Remove app-status stuff. No one uses it


# Actions
- [ ] Make action to update renv pkgs with `shinycoreci:::update_renv_pkgs()`
  - [ ] Run on any update to `inst/internal/apps`
- [ ] Deploying to Connect should push back connect urls
- [ ] Add validation that there is no usage of `shinycoreci::[^:]` in `./inst/internal/apps`
- [ ] Port actions from `rstudio/shinycoreci-apps`

# Apps
- [ ] App 217 needs to use
  `.Platform$OS.type == "windows" for determining windows support`
- [ ] Replace all usage of `shinycoreci::platform_rversion()` with `shinytest2::platform_variant()`
- [ ] Replace `shinycoreciapps::testthat_shinyjster()` with `shinyjster::testthat_shinyjster()`

- [ ] Move skip logic to inside tests
  - [ ] 181-report-image
  - [ ] 182-report-png
  - [ ] 183-report-cairo
  - [ ] 184-report-ragg
  - [ ] 193-reactlog-dynamic-ui
  - [ ] 301-bs-themes
  - [ ] 302-bootswatch-themes

# Done
- [x] `deploy_apps()`
- [x] `view_test_images()`
- [x] `test_in_browser()`
- [x] `test_in_connect()`
- [x] `test_in_shinyappsio()`
- [ ] `test_in_sso()` / `test_in_ssp()`
- [x] `test_in_ide()`
  - [x] Test in terminal
  - [ ] Test in IDE

- [ ] `test_in_ci()`
  - [x] formerly `test_run_tests()`
  - [ ] test results should be printed to log
  - [x] Changed data structure. Add version
  - [ ] Remove `test_path` from data structure; Use version to parse old files

- [x] Move `testthat_shinyjster()` to `{shinyjster}` to avoid bad installs


- [x] `./docker.R`
- [ ] Trim triple colon methods

## After merge
- [ ] `fix_all_gha_branches()`
- [ ] `view_test_diff()`
- [ ] `view_test_results()`

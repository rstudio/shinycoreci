# Shiny Core CI reusable workflows

## Usage:

The workflow below should be copied into your repo.

Adjust the `8` in the schedule to match the number of letters in the package name to insert some time variance. Otherwise, the PAT rate limit will be hit with all repos being tested at the same time.

**./github/workflows/R-CMD-check.yaml**
```
on:
  push:
    branches: [main, rc-**]
  pull_request:
    branches: [main]
  schedule:
    - cron:  '0 8 * * 0' # every sunday

name: Package checks

jobs:
  website:
    uses: rstudio/shinycoreci/.github/workflows/call-website.yaml@v1
  routine:
    uses: rstudio/shinycoreci/.github/workflows/call-routine.yaml@v1
  R-CMD-check:
    uses: rstudio/shinycoreci/.github/workflows/call-R-CMD-check.yaml@v1
```

## Workflows

A reusable workflow is a workflow that is defined in a single location but can be executed from another location as if it was locally defined. Link: https://docs.github.com/en/actions/learn-github-actions/reusing-workflows

There are three main reusable workflows to be used by packages in the shiny-verse

* `call-pkgdown.yaml`
  * This is a wrapper for building a pkgdown website and deploying it to the `gh-pages` branch of the repo.
  * Packages included in the `./DESCRIPTION` field `Config/Needs/website` will also be installed
  * Parameters:
    * `extra-packages`: Installs extra packages not listed in the `./DESCRIPTION` file to be installed. Link: https://github.com/r-lib/actions/tree/v1/setup-r-dependencies
    * `cache-version`: The cache key to be used. Link: https://github.com/r-lib/actions/tree/v1/setup-r-dependencies
    * `pandoc-version`: Sets the pandoc version to be installed. Link: https://github.com/r-lib/actions/tree/master/setup-pandoc
    * `check-title`: If set, will disable `rmarkdown`'s check for having the vignette title and the document title match
* `call-routine.yaml`
  * Performs many common tasks for packages in the shiny-verse
    * Check for url redirects in `rc-v**` branches
    * Making sure the documentation is up to date
    * Make sure the `README.md` is the latest version
    * Set the `./package.json` `version` field to match the `./DESCRIPTION` `Version` field
    * Calls `yarn build` and commits any changes in `./inst` and `./srcts`
    * Runs `before-ritual-push.R` (see below)
    * Pushes any new git commits to the repo
    * Runs `after-ritual-push.R` (see below)
    * Checks code coverage with `covr`
    * Checks for broken lints
    * Calls `yarn test`
  * Packages included in the `./DESCRIPTION` field `Config/Needs/routine` will also be installed
  * Parameters:
    * `extra-packages`, `cache-version`, `pandoc-version`: Same as in `call-pkgdown.yaml`
    * `node-version`: Version of `node.js` to install
    * `covr`: Runs code coverage
* `call-R-CMD-check.yaml`
  * Performs `R CMD check .` on your package
  * Parameters:
    * `extra-packages`, `cache-version`, `pandoc-version`: Same as in `call-pkgdown.yaml`
    * `macOS`: `macOS` runtime to use
    * `windows`: `windows` runtime to use
    * `ubuntu`: `ubuntu` runtime to use. To use more than one ubuntu value, send in a value separated by a space. For example, to test on ubuntu 18 and 20, use `"ubuntu-18.04 ubuntu20.04"`. The first ubuntu value will be tested using the `"devel"` R version.
    * `release-only`: Logical that determines if only the `"release"` R versions should be tested
    * `run-dont-test`: Runs `R CMD check .` with the extra `--run-donttest` argument

## Customization

There are a set of known files that can be run. The file just needs to exist to be run. No extra configuration necessary.

The files must exist in the `./.github/shinycoreci-step/` folder. Such as `./.github/shinycoreci-step/before-ritual-push.R`.

Files:
* `before-build-site.R` / `before-build-site.sh`
  * Run in `call-pkgdown.yaml` before the site is built
* `before-ritual-push.R` / `before-ritual-push.sh`
  * Run in `call-routine.yaml`. Runs before the local commits are pushed back to the repo
* `after-ritual-push.R` / `after-ritual-push.sh`
  * Run in `call-routine.yaml`. Runs after the local commits are pushed back to the repo. Useful to execute code that does not produce files that should be commited back to the repo
* `before-check.R` / `before-check.sh`
  * Run in `call-R-CMD-check.yaml` before any `R CMD check .` are called
* `after-check.R` / `after-check.sh`
  * Run in `call-R-CMD-check.yaml` after all `R CMD check .` are called
* `before-install.R` / `before-install.sh`
  * Run in `./.github/actions/install-r-package` after R is installed, but before the local package dependencies are installed.

These scripts should be done for their side effects, such as copying files or installing dependencies.

For example, a common use case for using a shell script over an R script would be to install system dependencies. Since installation is usually **O**perating**S**ystem specific, you'll likely want to make use of System environment variables, such as `$RUNNER_OS`. Link: https://docs.github.com/en/actions/learn-github-actions/environment-variables

Example usage of `before-install.sh`:
``` bash
if [ "$RUNNER_OS" == "macOS" ]; then
  brew install cairo
fi
```

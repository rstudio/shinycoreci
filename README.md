# shinycoreci - _test_results

## GHA Integration

Location of `build-site.yaml` workflow file: https://github.com/rstudio/shinycoreci/blob/_test_results/.github/workflows/build-site.yaml

### Actions performed

On push to `_test_results` branch...

* GHA will check out the latest `_test_results` branch into the local folder.
* GHA will check out the latest `gh-pages` branch into the `./_gh-pages` folder.
* GHA will install R and necessary package dependencies.
* Run `./build_site.R`
  * Read the *modify times* of each file in `_test_results` and processing files
  * Compare *modify times* to *modify times* of output files
  * If any input file is newer than the output file, reprocess the documen
  * If reprocessing, render `./render-results.Rmd` given proper subset of data
    * Save output to `./_gh-pages/results/YEAR/MONTH/DAY/index.html
  * Update `./_gh-pages/results/index.html` to redirect to the most recent results
* Within the `./_gh-pages` directory
  * Add any files that have been altered
  * Commit and push back any changes to the `gh-pages` website
    * Final results are

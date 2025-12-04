# Fix all `_snaps` files and merge all `gha-` branches

This method will apply patches from corresponding GitHub branches for
each R and Operating System combination. Changes will not be committed
or pushed back to GitHub. The user will need to perform this action
manually.

## Usage

``` r
fix_snaps(
  sha = git_sha(repo_dir),
  ...,
  ask_apps = FALSE,
  ask_branches = TRUE,
  ask_if_not_main = TRUE,
  repo_dir = rprojroot::find_package_root_file()
)
```

## Arguments

- sha:

  git sha of base branch to look for

- ...:

  Extra arguments passed to
  [`shinytest::viewTestDiff`](https://rdrr.io/pkg/shinytest/man/viewTestDiff.html)

- ask_apps, ask_branches:

  Logical which allows for particular apps or branches are to be
  inspected

- ask_if_not_main:

  Logical which will check if `main` is the base branch

- repo_dir:

  Root repo folder path

## Details

Note: This function will NOT fix `shinyjster` failures.

Outline of steps performed:

1.  Validate the current git branch is `main`

2.  Validate there are no git changes or untracked files in the current
    base branch

3.  Validate there are `.new` \_snaps files

4.  Create patch files for each corresponding `gha-` branch in
    `./patches`

5.  Ask which branches should be applied. Filter patch files accordingly

6.  Ask which app changes should be kept

7.  Apply patch files

8.  Call
    [`accept_snaps()`](https://rstudio.github.io/shinycoreci/reference/accept_snaps.md)
    on all app folders

9.  Undo changes to app that were not selected

10. Prompt user to commit and push changes back to GitHub

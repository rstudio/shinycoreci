
#' Fix All Failing Shinytest Diffs and Merge All `gha-` Branches
#'
#' Function to walk the user through merging all `gha-` branches.  This function will NOT push to the repository. Users must `git push` themselves.
#'
#' This function will NOT fix `shinyjster` failures.
#'
#' Outline of steps performed:
#' 1. Validate there are no git changes or untracked files in the current base branch
#' 2. Validate there are no unexpected shinytest folders
#' 3. If `isTRUE(ask)`, ask for which branches to work with
#' 4. Find all apps to update
#' 5. For each failing shinytest app, accept / reject shinytest changes in each `gha-` branch. Add an individualized commit message including the app and environment flavor information
#' 6. For each `gha-` branch, validate there are no unexpected shinytest folders. (Should be no unexpected folders after accepting / rejecting apps.)
#' 7. For each `gha-` branch, merge into the base branch.
#' 8. For each `gha-` branch, delete the locally checked out `gha-` branch. (Cleans up the local repo.)
#' 9. Tell the user to call `git push`.
#'
#' @param dir Root app folder path
#' @param sha git sha of base branch to look for
#' @param ... Extra arguments passed to `shinytest::viewTestDiff`
#' @param ask Logical which allows for particular branches to be inspected
#' @param merge Logical which merges all branches after viewing test results
#' @param commit Logical which determines if shinytest results should be committed
#' @param repo_dir Root repo folder path
#' @export
fix_all_gha_branches <- function(
  dir = "apps",
  sha = git_sha(dir),
  ...,
  merge = FALSE,
  commit = merge,
  ask = interactive(),
  repo_dir = file.path(dir, "..")
) {
  original_sys_call <- sys.call()
  validate_core_pkgs()

  if (length(git_diff(dir)) > 0) {
    message("Current git diff: ")
    message(paste0(git_diff(dir), collapse = "\n"))
    stop("Make sure there are no uncommited changes. Please call `git stash` or commit the changes.")
  }
  if (length(git_untracked_files(dir)) > 0) {
    message("Current untracked files and folders: ")
    message(paste0(git_untracked_files(dir), collapse = "\n"))
    stop("Make sure there are no untracked files. Please remove the files or commit the changes.")
  }

  if (isTRUE(merge) && !isTRUE(commit)) {
    stop("You can't `merge` if you do not enable `commit`")
  }

  validate_no_unexpected_shinytest_folders(dir)

  branches <- gha_remotes_latest(dir = dir, sha = sha)
  if (length(branches) == 0) {
    message("Did not find any branches for sha: ", sha)
    message("Be sure to run this function in your base branch. Current branch: ", git_branch(dir))
    return()
  }


  git_cmd_ <- function(..., git_dir = dir) {
    git_cmd(git_dir, paste0(...))
  }
  git_checkout <- function(git_branch_val) {
    message("git checkout ", git_branch_val)
    git_cmd_("git checkout ", git_branch_val)
  }

  original_git_branch <- git_branch(dir)
  on.exit({
    message("") # add a blank line
    git_checkout(original_git_branch)
  }, add = TRUE)

  message("\nFinding apps to view shinytest diff")
  apps_to_fix <-
    lapply(branches, function(branch) {
      git_checkout(branch)
      find_bad_shinytest_files(dir)
    })
  names(apps_to_fix) <- branches

  message("\nInspecting apps:")
  lapply(names(apps_to_fix), function(branch_name) {
    branch_apps <- apps_to_fix[[branch_name]]
    if (length(branch_apps) == 0) return()
    cat("* ", branch_name, "\n", sep = "")
    cat(paste0("  - ", shinytest_current_names(branch_apps), collapse = "\n"), "\n")
  })

  if (isTRUE(ask)) {
    message("")
    ans <- utils::menu(c("(All branches)", branches), graphics = FALSE, title = "Select the Git branches you'd like to use")
    # ans = 0; all
    # ans = 1; all
    if (ans > 1) {
      # if ans is not 'all', subset the folders
      ans_pos <- ans - 1
      branches <- branches[ans_pos]
      apps_to_fix <- apps_to_fix[branches]
    }
  }

  all_apps_to_fix <- unique(unlist(
      unname(apps_to_fix),
      recursive = FALSE
    ))

  branch_message <- function(branch, ...) {
    message(branch, " - ", ...)
  }

  # for each branch
  pr <- progress_bar(
    total = length(unlist(apps_to_fix, recursive = FALSE)),
    format = paste0("\n[:current/:total, :eta/:elapsed] :app : :testname; :branch")
  )
  # for each app
  lapply(all_apps_to_fix, function(app_folder_info) {
    app_folder <- app_folder_info$app
    app_testname <- app_folder_info$testname
    app_test_path <- app_folder_info$path
    # for each branch
    lapply(branches, function(branch) {

      # if this branch doesn't need to fix this app, return early
      branch_apps <- unlist(lapply(apps_to_fix[[branch]], `[[`, 1)) #inefficient, but ok
      if (! app_folder %in% branch_apps) {
        return()
      }

      # only tick for valid apps
      pr$tick(tokens = list(
        app = app_folder,
        testname = app_testname,
        branch = branch
      ))

      suffix <- shinytest_suffix(branch)
      git_checkout(branch)

      test_diff <- shinytest__view_test_diff(
        appDir = file.path(dir, app_folder),
        suffix = suffix,
        interactive = TRUE,
        testnames = app_testname,
        ...
      )

      if (isTRUE(commit)) {

        commit_app_value <- paste0(basename(app_folder), " ", suffix)

        if (test_diff[[1]] == "reject") {
          branch_message(branch, "Committing the deletion of unmerged `*-current` folder: ", app_test_path)
          git_cmd_("git rm -r ", app_test_path)
          git_cmd_("git commit -m 'gha - Reject test changes: ", commit_app_value, "'")
        } else {
          # accept
          branch_message(branch, "Committing the updated tests of folder: ", app_folder)
          # adds new and deleted files in the `app_folder`
          git_cmd_("git add -u ", app_folder)
          git_cmd_("git commit -m 'gha - Accept test changes: ", commit_app_value, "'")
        }
      }

    })

    # make a noise because it helps me know it's a new app
    utils::alarm()
  })

  # at this point, all branches should be updated and ready to be merged

  # verify all outstanding branches have no *-current folders
  message("\nChecking to make sure all git branches contain no *-current shinytest folders")
  lapply(branches, function(branch) {
    git_checkout(branch)
    validate_no_unexpected_shinytest_folders(dir)
  })

  # go to base branch
  git_checkout(original_git_branch)

  if (isTRUE(merge)) {
    message("\nAttempting to automatically merge (and locally delete) all branches into ", original_git_branch)

    # merge all outstanding branches
    lapply(branches, function(branch) {
      branch_message(original_git_branch, "Merging ", branch, " into ", original_git_branch)
      git_cmd_("git merge ", branch)
      had_merge_conflict <- FALSE

      unmerged_files <- git_cmd_("git diff --name-only --diff-filter=U")
      if (length(unmerged_files) > 0) {
        stop("Merge conflict found when merging '", branch, "' into '", original_git_branch, "'.\nPlease fix the merge conflict and call ", format(original_sys_call))
      }
    })

    git_checkout(original_git_branch)
    validate_no_unexpected_shinytest_folders()

    # git branch --merged
    message("\nDeleting all merged branches")
    git_checkout(original_git_branch)
    lapply(branches, function(branch) {
      branch_message(original_git_branch, "Deleting local ", branch)
      git_cmd_("git push origin ", branch)
      git_cmd_("git branch -d ", branch)
    })

  }

  if (isTRUE(commit) || isTRUE(merge)) {
    on.exit({
      message("\nDone!")
      message("Ready to push to origin/", original_git_branch)
      message("")
      message("git push")
    }, add = TRUE)
  }

  invisible(all_apps_to_fix)
}




# Note: Logic should be duplicated in ci-runtests.yml pre-check job
validate_no_unexpected_shinytest_folders <- function(dir = "apps") {
  existing_current_folders <- shinytest_current_folder(dir)
  if (length(existing_current_folders) > 0) {
    stop("There should be no *-current folders. Found: \n", paste0("* ", existing_current_folders, collapse = "\n"))
  }
  existing_expected_folders <- shinytest_expected_no_suffix_folder(dir)
  if (length(existing_expected_folders) > 0) {
    stop("There should be no *-expected folders. Found: \n", paste0("* ", existing_expected_folders, collapse = "\n"))
  }
}

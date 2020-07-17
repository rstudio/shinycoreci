
#' View Shinytest Diff
#'
#' @param suffix Test output suffix to compare against
#' @param dir Root folder path
#' @param ... Extra arguments passed to `shinytest::viewTestDiff`
#' @export
view_all_test_diff <- function(dir = "apps", sha = git_sha(dir), ask = interactive(), ..., repo_dir = file.path(dir, "..")) {
  original_sys_call <- sys.call()
  validate_core_pkgs()

  validate_no_unexpected_shinytest_folders(dir)

  branches <- gha_remotes_latest(dir = dir, sha = sha)
  if (length(branches) == 0) {
    message("Did not find any branches for sha: ", sha)
    message("Be sure to run this function in your base branch. Current branch: ", git_branch(dir))
    return()
  }


  if (isTRUE(ask)) {
    ans <- utils::menu(c("(All branches)", branches), graphics = FALSE, title = "Select the Git branches you'd like to use")
    # ans = 0; all
    # ans = 1; all
    if (ans > 1) {
      # if ans is not 'all', subset the folders
      ans_pos <- ans - 1
      branches <- branches[ans_pos]
    }
  }

  app_dir <- dir # must rename to avoid param error
  git_cmd_ <- function(..., dir = app_dir) {
    git_cmd(dir, paste0(...))
  }
  git_checkout <- function(git_branch_val) {
    message("git checkout: ", git_branch_val)
    git_cmd_("git checkout ", git_branch_val)
  }

  original_git_branch <- git_branch(dir)
  on.exit({
    git_checkout(original_git_branch)
  }, add = TRUE)

  message("\nFinding apps to view shinytest diff")
  apps_to_fix <-
    lapply(branches, function(branch) {
      git_checkout(branch)
      find_bad_shinytest_files(dir)
    })
  names(apps_to_fix) <- branches

  all_apps_to_fix <- sort(unique(unname(unlist(apps_to_fix))))

  message("\nInspecting apps:")
  print(all_apps_to_fix)

  branch_message <- function(branch, ...) {
    message(branch, " - ", ...)
  }

  # for each branch
  pr <- progress::progress_bar$new(
    total = length(all_apps_to_fix) * length(branches),
    format = paste0("\n[:current/:total, :eta/:elapsed] :app; :branch"),
    show_after = 0,
    clear = FALSE
  )
  # for each app
  lapply(all_apps_to_fix, function(app_folder) {
    # for each branch
    lapply(branches, function(branch) {
      pr$tick(tokens = list(app = app_folder, branch = branch))

      # if this branch doesn't need to fix this app, return early
      branch_apps <- apps_to_fix[[branch]]
      if (! app_folder %in% branch_apps) {
        return()
      }

      suffix <- shinytest_suffix(branch)
      git_checkout(branch)

      test_diff <- shinytest__view_test_diff(appDir = file.path(dir, app_folder), suffix = suffix, interactive = TRUE, ...)

      commit_app_value <- paste0(basename(app_folder), " ", suffix)

      if (test_diff[[1]] == "reject") {
        current_folder <- shinytest_current_folder(file.path(dir, app_folder))
        branch_message(branch, "Committing the deletion of unmerged `*-current` folder: ", current_folder)
        git_cmd_("git rm ", current_folder)
        git_cmd_("git commit -m 'gha - Reject test changes: ", commit_app_value, "'")
      } else {
        # accept
        branch_message(branch, "Committing the updated tests of folder: ", app_folder)
        # adds new and deleted files in the `app_folder`
        git_cmd_("git add -u ", app_folder)
        git_cmd_("git commit -m 'gha - Accept test changes: ", commit_app_value, "'")
      }
    })

    # make a noise because it helps me know it's a new app
    utils::alarm()
  })

  # at this point, all branches should be updated and ready to be merged

  # verify all outstanding branches have no *-current folders
  message("\nValidate all branches contain no *-current shinytest folders")
  lapply(branches, function(branch) {
    git_checkout(branch)
    validate_no_unexpected_shinytest_folders(dir)
  })

  message("\nMerge (and locally delete) all branches into ", original_git_branch)
  # go to base branch
  git_checkout(original_git_branch)

  # merge all outstanding branches
  lapply(branches, function(branch) {
    branch_message(original_git_branch, "Merging ", branch, " into ", original_git_branch)
    git_cmd_("git merge ", branch)
    had_merge_conflict <- FALSE

    while ({
      unmerged_files <- git_cmd_("git diff --name-only --diff-filter=U")
      length(unmerged_files) > 0
    }) {
      had_merge_conflict <- TRUE
      message("\n\n")
      message(paste0(git_cmd_("git status"), collapse = "\n"))
      message("\nUnmerged files detected!")
      message(paste0("* ", unmerged_files, collapse = "\n"))

      ans <- utils::menu(c("Add all files", "Delete all files", "Manually fix the merge conflict", "Abort merge (and quit)"), graphics = FALSE, title = "Would you like to")
      if (ans <= 1) {
        # auto delete
        lapply(unmerged_files, function(unmerged_file) {
          git_cmd_(dir = repo_dir, "git add ", unmerged_file)
        })
      } else if (ans == 2) {
        # auto delete
        lapply(unmerged_files, function(unmerged_file) {
          git_cmd_(dir = repo_dir, "git rm ", unmerged_file)
        })
      } else if (ans == 3) {
        # manual
        utils::menu(c("yes"), graphics = FALSE, title = "Merge conflict fixed?")
      } else if (ans == 3) {
        message("Aborting the merge")
        git_cmd_("git merge --abort")
        stop("Stopping ", original_sys_call)
      }
    }
    if (had_merge_conflict) {
      git_cmd_("git commit -m \"gha - Merging ", branch, " into ", original_git_branch, "\"")
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


  branch_message(original_git_branch, "Ready to push to origin/", original_git_branch)
  message("git push")
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

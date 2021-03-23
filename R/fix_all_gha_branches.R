
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
#' @param save_results Logical which commits and merges all branches after viewing test results
#' @param ask_apps,ask_branches Logical which allows for particular apps branches to be inspected
#' @param ask_if_not_master Logical which will check if `master` is the base branch
#' @param repo_dir Root repo folder path
#' @export
fix_all_gha_branches <- function(
  dir = "apps",
  sha = git_sha(dir),
  ...,
  save_results = NULL,
  ask_apps = FALSE,
  ask_branches = TRUE,
  ask_if_not_master = TRUE,
  repo_dir = file.path(dir, "..")
) {
  original_sys_call <- sys.call()
  validate_core_pkgs()

  if (!is.null(list(...)$merge)) {
    stop("`merge` is deprecated. Use `save_results` instead")
  }
  if (!is.null(list(...)$commit)) {
    stop("`commit` is deprecated. Use `save_results` instead")
  }

  if (isTRUE(ask_if_not_master)) {
    if (git_branch(dir) != "master") {
      ans <- utils::menu(
        c(
          "Yes; `ask_if_not_master = FALSE`",
          "No"
        ),
        graphics = FALSE,
        title = paste0("Is the base branch of `", git_branch(dir), "` correct?")
      )
      if (ans != 1) {
        stop("The base git branch is not correct. Fix the base branch and try again.")
      }
    }
  }

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

  if (!(identical(save_results, TRUE) || identical(save_results, FALSE))) {
    ans <- utils::menu(
      c("Yes; `save_results = TRUE`", "No; `save_results = FALSE`"),
      graphics = FALSE,
      title = "Would you like to git commit and merge these test approvals / rejections?"
    )
    save_results <- (ans == 1)
  }

  validate_no_unexpected_shinytest_folders(dir)

  branches <- gha_remotes_latest(dir = dir, sha = sha)
  if (length(branches) == 0) {
    message("Did not find any branches for sha: ", sha)
    message("Be sure to run this function in your base branch or after GHA has finished.\nCurrent branch: ", git_branch(dir))
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
  # get all app info into a data.frame for easy subsetting
  app_info_dt <- do.call(rbind, unname(unlist(
    Map(names(apps_to_fix), apps_to_fix, f = function(branch_name, branch_apps) {
      Map(branch_apps, f = function(branch_app_info) {
        branch_parts <- strsplit(branch_name, "-")[[1]]
        as.data.frame(append(
          branch_app_info,
          list(
            branch = branch_name,
            os = branch_parts[[length(branch_parts)]],
            r_version = branch_parts[[length(branch_parts) - 1]]
          )
        ))
      })
    }),
    recursive = FALSE
  )))
  app_info_dt$app_testname <- paste0(format(app_info_dt$app), ": ", format(app_info_dt$testname))
  # reorder apps
  app_info_dt <- app_info_dt[order(app_info_dt$app, app_info_dt$testname, app_info_dt$os, app_info_dt$r_version), ]


  print_apps <- function() {
    app_info_dt_fmt <- app_info_dt
    app_info_dt_fmt$os <- ifelse(app_info_dt_fmt$os == "Windows", "Wndws", app_info_dt_fmt$os)
    ignore <- lapply(
      split(app_info_dt_fmt, app_info_dt$app_testname),
      function(app_info_dt_for_combo) {
        app_testname <- app_info_dt_for_combo$app_testname[[1]]
        os_r_version <- paste0(
          app_info_dt_for_combo$os, "-", app_info_dt_for_combo$r_version,
          collapse = ", "
        )
        cat("* ", app_testname, " ; ", os_r_version, "\n", sep = "")
      }
    )
  }

  if (isTRUE(ask_branches)) {
    message("\nApps:")
    print_apps()
    app_branches <- sort(unique(app_info_dt$branch))
    cat("\n")
    ans <- utils::menu(
      c("(All branches); `ask_branches = FALSE`", app_branches),
      graphics = FALSE,
      title = "Select the Git branches you'd like to use"
    )
    # ans = 0; all
    # ans = 1; all
    if (ans > 1) {
      # if ans is not 'all', subset the `app_info_dt`
      ans_pos <- ans - 1
      branches <- app_branches[ans_pos]
      app_info_dt <- app_info_dt[app_info_dt$branch %in% branches, ]
    }
  }

  if (isTRUE(ask_apps)) {
    message("\nApps:")
    print_apps()
    app_testnames <- sort(unique(app_info_dt$app_testname))
    cat("\n")
    ans <- utils::menu(
      c("(All apps); `ask_apps = FALSE`", app_testnames),
      graphics = FALSE,
      title = "Select the App / Test you'd like to use"
    )
    # ans = 0; all
    # ans = 1; all
    if (ans > 1) {
      # if ans is not 'all', subset the folders
      ans_pos <- ans - 1
      app_testnames <- app_testnames[ans_pos]
      app_info_dt <- app_info_dt[app_info_dt$app_testname %in% app_testnames, ]
    }
  }

  message("\nTesting Apps:")
  print_apps()

  branch_message <- function(branch, ...) {
    message(branch, " - ", ...)
  }

  # for each branch
  pr <- progress_bar(
    total = nrow(app_info_dt),
    format = paste0("\n[:current/:total, :eta/:elapsed] :app : :testname; :branch")
  )
  # for each combo
  Map(
    app_info_dt$app,
    app_info_dt$testname,
    app_info_dt$path,
    app_info_dt$branch,
    f = function(app_folder, app_testname, app_test_path, branch) {
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

      if (isTRUE(save_results)) {

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
      } else {
        branch_message(branch, "Resetting all changes in ", app_folder)
        # undo all the things! Am not commiting, so we need to remove any changes
        git_cmd_("git checkout -- ", app_folder)
      }
    }
  )


  # at this point, all branches should be updated and ready to be merged
  if (isTRUE(save_results)) {
    # verify all outstanding branches have no *-current folders
    message("\nChecking to make sure all git branches contain no *-current shinytest folders")

    lapply(unique(app_info_dt$branch), function(branch) {
      git_checkout(branch)
      validate_no_unexpected_shinytest_folders(dir)
    })

    # go to base branch
    git_checkout(original_git_branch)

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

    on.exit({
      message("\nDone!")
      message("Ready to push to origin/", original_git_branch)
      message("")
      message("git push")
    }, add = TRUE)
  }

  invisible(app_info_dt)
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

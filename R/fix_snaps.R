
#' Fix all `_snaps` files and merge all `gha-` branches
#'
#' This method will apply patches from corresponding GitHub branches for each R and Operating System combination. Changes will not be committed or pushed back to GitHub. The user will need to perform this action manually.
#'
#' This function will NOT fix `shinyjster` failures.
#'
#' Outline of steps performed:
#' 1. Validate the current git branch is `main`
#' 1. Validate there are no git changes or untracked files in the current base branch
#' 2. Validate there are `.new` _snaps files
#' 3. Create patch files for each corresponding `gha-` branch in `./patches`
#' 4. Ask which branches should be applied. Filter patch files accordingly
#' 4. Ask which app changes should be kept
#' 5. Apply patches
#' 6. Undo changes to app that were not selected
#' 7. Call [`accept_snaps()`] on all app folders
#' 8. Prompt user to commit and push changes back to GitHub
#' 8. For each `gha-` branch, delete the locally checked out `gha-` branch. (Cleans up the local repo.)
#' 9. Tell the user to call `git push`.
#'
#' @param dir Root app folder path
#' @param sha git sha of base branch to look for
#' @param ... Extra arguments passed to `shinytest::viewTestDiff`
#' @param ask_apps,ask_branches Logical which allows for particular apps branches to be inspected
#' @param ask_if_not_main Logical which will check if `main` is the base branch
#' @param repo_dir Root repo folder path
#' @export
fix_snaps <- function(
  sha = git_sha(repo_dir),
  ...,
  ask_apps = FALSE,
  ask_branches = TRUE,
  ask_if_not_main = TRUE,
  repo_dir = "."
) {
  original_sys_call <- sys.call()
  # validate_core_pkgs()

  apps_folder <- file.path(repo_dir, "inst", "apps")

  verify_if_not_main_branch(ask_if_not_main, repo_dir = repo_dir)
  verify_no_git_changes(repo_dir = repo_dir, apps_folder = apps_folder)
  verify_no_untracked_files(repo_dir = repo_dir, apps_folder = apps_folder)

  verify_no_new_snaps(repo_dir, apps_folder)

  branches <- gha_remotes_latest(repo_dir, sha = sha)
  if (length(branches) == 0) {
    message("Did not find any branches for sha: ", sha)
    message("Be sure to run this function in your base branch or after GHA has finished.\nCurrent branch: ", git_branch(repo_dir))
    return()
  }

  git_cmd_ <- function(..., git_dir = repo_dir) {
    # Turn warnings into immediate errors
    withr::with_options(list(warn = 2), {
      git_cmd(git_dir, paste0(...))
    })
  }
  git_checkout <- function(git_branch_val, quiet = FALSE) {
    if (!quiet) message("git checkout ", git_branch_val)
    git_cmd_("git checkout ", git_branch_val, if (quiet) " --quiet")
    invisible()
  }

  original_git_branch <- git_branch(repo_dir)
  withr::defer({
    message("") # add a blank line
    git_checkout(original_git_branch)
  })

  # Create patch files
  patch_folder <- "patches"
  if (dir.exists(patch_folder)) unlink(patch_folder, recursive = TRUE)
  dir.create(patch_folder, showWarnings = FALSE)

  pb <- progress_bar(
    total = length(branches),
    format = "Create patch file - :name [:bar] :current/:total"
  )
  patch_files <- lapply(branches, function(branch) {
    pb$tick(tokens = list(name = branch))
    if(grepl("(/|\\.\\.)", branch)) stop("Non-safe branch name: ", branch)
    patch_file <- file.path(patch_folder, paste0(branch, ".patch"))
    if (!file.exists(patch_file)) {
      withr::defer({
      # Go back to original branch
        git_checkout(original_git_branch, quiet = TRUE)
        # Remove local copy of `gha-` branch. No need for it to exist locally anymore
        git_cmd_("git branch -d '", branch, "' --quiet")
      })
      # Go to branch
      git_checkout(branch, quiet = TRUE)
      # Make patch file
      git_cmd_(paste0("git format-patch '", original_git_branch, "' --stdout > ", patch_file))
    }

    patch_file
  })
  names(patch_files) <- branches
  patch_files <- Filter(patch_files, f = file.exists)

  if (length(patch_files) == 0) {
    message("\nNo patch files were created. Quitting early")
    return(NULL)
  }

  # Find app names in patch files
  pb <- progress_bar(total = length(patch_files), format = "Find app names - :name [:bar] :current/:total")
  files_changed <- lapply(patch_files, function(patch_file) {
    pb$tick(tokens = list(name = patch_file))

    # Perform `grep` on disk as to not read it into the R session
    app_lines <- system2("grep", c("-F", "/inst/apps", patch_file), stdout = TRUE)

    test_names <- unique(unlist(
      regmatches(app_lines, gregexpr("/inst/apps/([^ ]+)", app_lines))
    ))
    test_names
  })
  names(files_changed) <- names(patch_files)
  files_changed <- files_changed[!vapply(files_changed, is.null, logical(1))]

  apps_changed <- lapply(files_changed, function(patch_files_changed) {
    valid_files <- Filter(patch_files_changed, f = function(patch_file_changed) {
      name_parts <- strsplit(patch_file_changed, "/")[[1]]
      name_parts_len <- length(name_parts)
      if (name_parts_len < 8) return(FALSE)
      if (name_parts[[name_parts_len]] == "") {
        return(NULL)
      }
      TRUE
    })
    app_names <- lapply(strsplit(valid_files, "/"), `[[`, 4)
    # list(
    #   app = unique(unlist(app_names)),
    #   testname = basename(dirname(valid_files)),
    #   path = valid_files
    # )
    unique(unlist(app_names))
  })

  # Get all app info into a data.frame for easy subsetting
  app_info_dt <- do.call(rbind, unname(unlist(
    Map(names(apps_changed), apps_changed, f = function(branch_name, apps_changed_names) {
      branch_parts <- strsplit(branch_name, "-")[[1]]
      Map(
        apps_changed_names,
        f = function(
          app_name
        ) {
          data.frame(
            app_name = app_name,
            branch = branch_name,
            os = branch_parts[[length(branch_parts)]],
            r_version = branch_parts[[length(branch_parts) - 1]]
          )
        }
      )
    }),
    recursive = FALSE
  )))
  branch_message <- function(branch, ...) {
    message(branch, " - ", ...)
  }

  app_info_dt <- app_info_dt[order(app_info_dt$app_name, app_info_dt$os, app_info_dt$r_version), ]

  print_apps <- function() {
    app_info_dt_fmt <- app_info_dt
    app_info_dt_fmt$app_name_fmt <- format(app_info_dt_fmt$app_name)
    app_info_dt_fmt$os <- ifelse(app_info_dt_fmt$os == "Windows", "Wndws", app_info_dt_fmt$os)
    ignore <- lapply(
      split(app_info_dt_fmt, app_info_dt$app_name),
      function(app_info_dt_for_combo) {
        app_name <- app_info_dt_for_combo$app_name_fmt[[1]]
        os_r_version <- paste0(
          app_info_dt_for_combo$os, "-", app_info_dt_for_combo$r_version,
          collapse = ", "
        )
        cat("* ", app_name, " ; ", os_r_version, "\n", sep = "")
      }
    )
  }

  if (isTRUE(ask_branches)) {
    message("\nApps:")
    print_apps()
    app_branches <- sort(unique(app_info_dt$branch))
    cat("\n")
    first_choice <- "(All branches); `ask_branches = FALSE`"
    ans <- utils::select.list(
      c(first_choice, app_branches),
      multiple = TRUE,
      graphics = FALSE,
      title = "Select the Git branches you'd like to use"
    )
    if ((length(ans) == 0) || (first_choice %in% ans)) {
      # Do not subset data
    } else {
      app_info_dt <- app_info_dt[app_info_dt$branch %in% ans, ]
    }
  }

  apps_rejected <- c()
  if (isTRUE(ask_apps)) {
    message("\nApps:")
    print_apps()
    app_names <- sort(unique(app_info_dt$app_name))
    cat("\n")
    first_choice <- "(All apps); `ask_apps = FALSE`"
    ans <- utils::select.list(
      c(first_choice, app_names),
      multiple = TRUE,
      graphics = FALSE,
      title = "Select the App / Test you'd like to use"
    )
    if ((length(ans) == 0) || (first_choice %in% ans)) {
      # Do not subset data
    } else {
      keep_rows_logical <- app_info_dt$app_name %in% ans
      apps_rejected <- unique(app_info_dt$app_name[!keep_rows_logical])
      app_info_dt <- app_info_dt[keep_rows_logical, ]
    }
  }

  message("\nFinal Apps:")
  print_apps()

  # Apply patch files
  patch_files_sub <- patch_files[names(patch_files) %in% app_info_dt$branch]
  pb <- progress_bar(total = length(patch_files_sub), format = "Apply patches - :name [:bar] :current/:total")
  Map(
    names(patch_files_sub),
    patch_files_sub,
    f = function(branch, patch_file) {
      pb$tick(tokens = list(name = patch_file))
      git_cmd_("git apply ", patch_file)
    }
  )

  if (length(apps_rejected) > 0) {
    message("Removing changes from rejected apps")
    pb <- progress_bar(total = length(apps_rejected), format = "Removing changes - :name [:bar] :current/:total")
    Map(
      apps_rejected,
      f = function(app_name) {
        pb$tick(tokens = list(name = app_name))
        git_cmd_("git checkout -- ", repo_app_path(repo_dir = repo_dir, app_name = app_name))
      }
    )
  }

  accept_snaps(repo_dir)

  message("\nUse `GitHub Desktop` to commit / push changes")

  invisible(app_info_dt)
}




# Note: Logic should be duplicated in pre-check GHA workflow
verify_no_new_snaps <- function(repo_dir = ".", folder = "inst/apps") {
  new_snaps <- dir(file.path(repo_dir, folder), pattern = "\\.new", recursive = TRUE, include.dirs = FALSE)
  if (length(new_snaps) > 0) {
    message("There should be no `.new` _snaps in `", folder, "`. Found: \n", paste0("* ", new_snaps, collapse = "\n"))
    message("\nCall `shinycoreci::accept_snaps()` to accept the new _snaps")
    stop("`.new` _snaps found")
  }
}



verify_if_not_main_branch <- function(ask_if_not_main, repo_dir) {
  if (isTRUE(ask_if_not_main)) {
    if (git_branch(repo_dir) != "main") {
      ans <- utils::menu(
        c(
          "Yes; `ask_if_not_main = FALSE`",
          "No"
        ),
        graphics = FALSE,
        title = paste0("Is the base branch of `", git_branch(repo_dir), "` correct?")
      )
      if (ans != 1) {
        stop("The base git branch is not correct. Fix the base branch and try again.")
      }
    }
  }
}


verify_no_git_changes <- function(repo_dir, apps_folder) {
  git_diff_ <- function() {
    git_diff(repo_dir, apps_folder)
  }

  if (length(git_diff_()) > 0) {
    message("Current git diff: ")
    message(paste0(git_diff_(), collapse = "\n"))
    stop("Make sure there are no uncommited changes. Please call `git stash` or commit the changes.")
  }
}


verify_no_untracked_files <- function(repo_dir, apps_folder) {
  withr::with_options(list(warn = 2), {
    system(paste0("find ", file.path(repo_dir, apps_folder), " -empty -type d -delete"))
  })
  untracked_files <- git_untracked_files(repo_dir, apps_folder)
  if (length(untracked_files) > 0) {
    message("Current untracked files and folders: ")
    message(paste0(untracked_files, collapse = "\n"))
    message("")
    unlink_code <- sub("Would remove ", "", untracked_files, fixed = TRUE)
    unlink_code <- paste0("  \"", unlink_code, "\"", collapse = ",\n")
    unlink_code <- paste0("unlink(c(\n", unlink_code, "\n), recursive = TRUE)")
    message("Code to remove these files / folders:\n", unlink_code)

    stop("Make sure there are no untracked files. Please remove the files or commit the changes.")
  }
}

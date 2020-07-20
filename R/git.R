# run a system command and get the response
run_system_cmd <- function(...) {
  cmd <- paste0(...)
  system(cmd, intern = TRUE)
}


git_cmd <- function(dir, cmd) {
  dir <- normalizePath(dir)
  owd <- setwd(dir)
  on.exit(setwd(owd), add = TRUE)
  run_system_cmd(cmd)
}


# get the branch name
git_branch <- function(dir) {
  git_cmd(dir, "git rev-parse --abbrev-ref HEAD")
}

# get the short sha
git_sha <- function(
  dir
) {
  git_cmd(dir, "git rev-parse --short HEAD")
}

git_fetch <- function(dir) {
  git_cmd(dir, "git fetch")
}


git_remotes <- function(dir, remote = "origin") {
  sub(
    paste0(remote, "/"), "",
    gsub(
      "(^\\s+|\\s+$)", "",
      git_cmd(dir, "git branch -r")
    )
  )
}


gha_remotes <- function(dir, sha = git_sha(dir)) {
  # get the latest remotes locally available
  git_fetch(dir)

  # retrieve remotes names
  remotes <- git_remotes(dir)
  remotes[grepl(paste0("^gha-", sha), remotes)]
}

gha_branch_information <- function(dir, sha = git_sha(dir), branches = gha_remotes(dir = dir, sha = sha)) {

  matches <- regmatches(
    branches,
    regexec(
      "gha-([^-]+)-(\\d{4})_(\\d{2})_(\\d{2})_(\\d{2})_(\\d{2})-([^-]+)-(.+)$",
      branches
    )
  )
  branch_info <- do.call(rbind, lapply(matches, function(match) {
    data.frame(
      branch = match[1],
      sha = match[2],
      r_version = match[8],
      platform = match[9],
      time = ISOdatetime(
        year = as.numeric(match[3]),
        month = as.numeric(match[4]),
        day = as.numeric(match[5]),
        hour = as.numeric(match[6]),
        min = as.numeric(match[7]),
        sec = 0,
        tz = "UTC"
      ),
      stringsAsFactors = FALSE
    )
  }))

  branch_info
}

gha_remotes_latest <- function(dir, sha = git_sha(dir)) {

  branch_info <- gha_branch_information(dir = dir, sha = sha)

  if (is.null(branch_info) || nrow(branch_info) == 0) {
    stop("No information found for sha: ", sha, " . Do you have a valid sha?")
  }

  # split by r version and platform
  split_branch_info <- split(branch_info, branch_info[c("r_version", "platform")])

  # get row with latest time
  min_time_info <- lapply(split_branch_info, function(run_info) {
    run_info[which.max(run_info$time), ]
  })

  ret <- do.call(rbind, min_time_info)
  rownames(ret) <- NULL
  ret$branch
}

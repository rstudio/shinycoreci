`%||%` <- function(x, y) {
  if (is.null(x)) {
    return(y)
  }
  return(x)
}


# Remove files, but only try to remove if they exist (so we don't get
# warnings).
rm_files <- function(filenames) {
  # Only try to remove files that actually exist
  filenames <- filenames[file.exists(filenames)]
  file.remove(filenames)
}


# Is this a SHA-1 hash? (vectorized)
is_sha <- function(x) {
  !is.na(x) &
    nchar(x) == 40 &
    sub("[0-9a-f]*", "", x) == ""
}


# Ask a yes no question defaulting to 'no'
ask_yes_no <- function(..., default = FALSE) {
  utils::askYesNo(
    paste0(...),
    default = default
  )
}

# returns TRUE is pkg is loaded with devtools
shinycoreci_is_loaded_with_devtools <- function() {
  ".__DEVTOOLS__" %in% ls(envir = asNamespace("shinycoreci"), all.names = TRUE)
}


dput_arg <- function(x) {
  f <- file()
  on.exit({
    close(f)
  })
  dput(x, f)
  ret <- paste0(readLines(f), collapse = "\n")
  ret
}
fn_arg <- function(name, val) {
  paste0(name, " = ", dput_arg(val))
}

trim_ws <- function (x) {
  gsub("^[[:space:]]+|[[:space:]]+$", "", x)
}
split_remotes <- function(x) {
  trim_ws(unlist(strsplit(x, ",[[:space:]]*")))
}


progress_bar <- function(..., show_after = 0, clear = FALSE, force = TRUE) {
  progress::progress_bar$new(
    ...,
    show_after = show_after,
    clear = clear,
    force = force
  )
}

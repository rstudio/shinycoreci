# TODO
# - Make method to check all images in git status?
#    * No. This requires too many permissions. Skipping for now.


setup_gha_image_diffs <- function(
  ...,
  min_diff = 3,
  repo_dir = ".",
  # location to save images
  out_dir = tempfile(),
  sha = git_sha(repo_dir)
  # # location of repo for comparisons
  # vanilla_repo_dir = "../z-shinycoreci.nosync"
) {
  ellipsis::check_dots_empty()
  repo_dir <- normalizePath(repo_dir)
  # vanilla_repo_dir <- normalizePath(vanilla_repo_dir)
  force(sha)
  withr::local_dir(repo_dir)

  out_dir <- "inst/img-diff-app"
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)


  proc_locs <- as.list(Sys.which(c("git", "gm")))
  if (proc_locs$git == "") stop("Please install git")
  if (proc_locs$gm == "") stop("Please install graphicsmagick via `brew install graphicsmagick` or `apt-get install graphicsmagick`")

  all_files <- system("git diff --name-only", intern = TRUE)
  png_files <- all_files[fs::path_ext(all_files) == "png" & grepl("^inst/apps/", all_files)]

  tmp_img_path <- file.path(out_dir, "tmp_original_image.png")
  # Extract original image so that two files can be compared
  get_original_file <- function(png_file) {
    system(paste0("git show HEAD:", png_file, " > ", tmp_img_path))
    tmp_img_path
  }
  on.exit(if (file.exists(tmp_img_path)) unlink(tmp_img_path))

  message("\nFinding images...")
  p <- progress::progress_bar$new(
    format = "[:current/:total;:eta] :name",
    total = length(png_files),
    show_after = 0,
    clear = FALSE
  )
  diffs <- lapply(png_files, function(png_file) {
    p$tick(tokens = list(name = png_file))
    # Compare images
    shinytest2::screenshot_max_difference(png_file, get_original_file(png_file))
  })
  # diffs <- as.list(seq_along(png_files))

  diffs <- setNames(diffs, png_files)
  # hist(unlist(diffs))

  diff_folder <- file.path(out_dir, "image_diffs")
  if (dir.exists(diff_folder)) unlink(diff_folder, recursive = TRUE)
  dir.create(diff_folder, showWarnings = FALSE, recursive = TRUE)

  bad_pngs <- names(diffs[diffs > min_diff])
  bad_diff_count <- unname(unlist(diffs[bad_pngs]))

  message("\nDiff images")
  p <- progress::progress_bar$new(
    format = "[:current;:total;:eta] :name",
    total = length(bad_pngs),
    show_after = 0,
    clear = FALSE
  )
  img_dt <-
    lapply(bad_pngs, function(bad_png) {
      p$tick(tokens = list(name = bad_png))
      san_path <- fs::path_sanitize(bad_png, "_")
      new_png <- fs::file_copy(
        bad_png,
        file.path(diff_folder, fs::path_ext_set(san_path, ".new.png")),
        overwrite = TRUE
      )
      orig_png <- fs::file_copy(
        get_original_file(bad_png),
        file.path(diff_folder, fs::path_ext_set(san_path, ".old.png")),
        overwrite = TRUE
      )
      diff_png <- file.path(diff_folder, san_path)
      system(paste0(
        "gm compare ", new_png, " ", orig_png, " -highlight-style assign -file ", diff_png
      ))

      dplyr::tibble(
        diff_png = diff_png,
        orig_png = orig_png,
        new_png = new_png
      )
    }) %>%
    dplyr::bind_rows()

  png_dt <- dplyr::tibble(
    file = bad_pngs,
    diff_png = img_dt$diff_png,
    orig_png = img_dt$orig_png,
    new_png = img_dt$new_png,
    diff_count = bad_diff_count
  ) %>%
    dplyr::mutate(
      # inst/apps/041-dynamic-ui/tests/testthat/_snaps/linux-4.0/mytest/022.png
      base = gsub("^inst/apps/", "", file),
      app = gsub("/.*$", "", base),
      snap = file.path(basename(dirname(base)), basename(base)),
      platform_combo = basename(dirname(dirname(base))),
      anchor = fs::path_sanitize(file, "_"),
    ) %>%
    dplyr::select(-base) %>%
    tidyr::separate_wider_delim(cols = "platform_combo", names = c("platform", "Rver"), delim = "-", cols_remove = FALSE)

  data_path <- file.path(out_dir, "data.json")
  writeLines(
    jsonlite::serializeJSON(png_dt, pretty = TRUE),
    data_path,
    useBytes = TRUE
  )

  data_path
}



#' @export
view_image_diffs <- function(
  ...,
  run_fix_snaps = TRUE,
  run_setup = TRUE,
  open_viewer = TRUE,
  repo_dir = ".",
  sha = git_sha(repo_dir)
) {
  ellipsis::check_dots_empty()
  if (run_fix_snaps) {
    fix_snaps(ask_apps = FALSE, ask_branches = FALSE, repo_dir = repo_dir, sha = sha)
  }
  if (run_setup) {
    setup_gha_image_diffs(repo_dir = repo_dir, sha = sha)
  }

  withr::local_dir(repo_dir)
  rmarkdown::render("inst/img-diff-app/diff.Rmd")
  if (open_viewer) {
    system("open inst/img-diff-app/diff.html")
  }
}

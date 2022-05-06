# rmarkdown::render("MyDocument.Rmd", params = list(
#   year = 2017,
#   region = "Asia",
#   printcode = FALSE,
#   file = "file2.csv"
# ))

library(dplyr)
library(tidyr)
library(lubridate)

days_to_display <- 10
save_folder <- "docs"

# # Pull in the repo location to view the test results
# dir <- Sys.getenv("SHINYCORECI_VIEW_TEST_RESULTS", unset = "__unknown")
# if (identical(dir, "__unknown")) {
#   stop("This app must be called with `shinycoreci::view_test_results()")
# }
# repo_dir <- normalizePath(dir, mustWork = TRUE)
# if ("shinycoreci-apps" != basename(repo_dir)) {
#   warning("This function should be called from the shinycoreci-apps repo")
# }
# print(repo_dir)
# curDir <- getwd()
# on.exit(setwd(curDir), add = TRUE)
# setwd(repo_dir)

strextract <- function(str, pattern) {
  regmatches(str, regexpr(pattern, str))
}


file_test_results <- function(file) {
  results <- test_results_import(file)
  dt <- bind_rows(results) %>%
    tibble::as_tibble() %>%
    mutate(gha_branch = gha_branch_name) %>%
    separate(
      "gha_branch_name",
      c("gha", "sha", "time", "r_version", "platform"),
      sep = "-"
    ) %>%
    select(-gha) %>%
    mutate(
      os = platform,
      platform = paste(platform, r_version, sep = "-"),
      time = as.POSIXct(time, format = "%Y_%m_%d_%H_%M"),
      date = as.Date(time),
      sha = paste0(branch_name, "@", sha)
    ) %>%
    arrange(desc(time))

  ret <- tibble(
    results = list(dt %>% select(app_name, status, result)),
  )
  bind_cols(
    ret,
    select(dt, - app_name, -status, -result)[1, ]
  )
}

test_results_import <- function(file) {
  json <- jsonlite::read_json(file, simplifyVector = TRUE)
  json$results$gha_branch_name <- json$gha_branch_name
  json$results$branch_name <- json$branch_name
  json$results
}

parse_data_files <- function(files) {
  pb <- progress::progress_bar$new(
    length(files),
    format = "Reading data [:bar] :current/:total eta::eta",
    force = TRUE,
    # show_after = 0,
    clear = FALSE
  )
  lapply(files, function(file) {
    pb$tick()
    file_test_results(file)
  })
}

log_files <- Sys.glob("__test_results/*.json")

log_df <-
  log_files %>%
  # head(20) %>%
  lapply(file.info) %>%
  bind_rows() %>%
  {
    dt <- .
    dt$file <- rownames(dt)
    rownames(dt) <- NULL
    dt
  } %>%
  as_tibble() %>%
  select(file, mtime) %>%
  mutate(
    data = parse_data_files(file)
  ) %>%
  unnest(data) %>%
  filter(branch_name == "main") %>%
  force()


min_date <- min(log_df$date)
max_date <- max(log_df$date)

max_date_url <-
  paste0(
    strsplit(as.character(max_date), "-")[[1]],
    "/",
    collapse = ""
  )

cat(file = paste0(save_folder, "/index.html"), "
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv=\"refresh\" content=\"0; url='", max_date_url, "'\" />
  </head>
  <body>
    <p><a href=\"", max_date_url, "\">Click for latest results</a></p>
  </body>
</html>
")

pad2 <- function(x) {
  x <- as.character(x)
  x_len <- nchar(x)
  if (x_len == 0) "00"
  else if (x_len == 1) paste0("0", x)
  else x
}

unique_platforms <- sort(unique(log_df$platform))

# For each date, try to build the site if newer files are available
pb <- progress::progress_bar$new(
  total = as.numeric(as.difftime(max_date - min_date)) + 1,
  format = "Processing site [:bar] :date :current/:total eta::eta\n",
  force = TRUE,
  # show_after = 0,
  clear = FALSE
)
cur_date <- max_date
while (cur_date >= min_date) {
  pb$tick(tokens = list(date = cur_date))

  save_file <- file.path(
    save_folder,
    pad2(lubridate::year(cur_date)),
    pad2(lubridate::month(cur_date)),
    pad2(lubridate::day(cur_date)),
    "index.html"
  )

  sub_df <- log_df %>% filter(
    date >= cur_date - lubridate::days(days_to_display),
    date <= cur_date
  )

  should_build_site <- local({
    if (!file.exists(save_file)) {
      return(TRUE)
    }
    # If the output file is older than the input files, rebuild
    save_file_info <- as.list(file.info(save_file)[1, ])
    if (any(sub_df$mtime > save_file_info$mtime)) {
      return(TRUE)
    }

    # If any of these files are newer, rebuild
    for (file_path in c(
      "render-results.Rmd",
      "build_site.R",
      ".github/workflows/build-site.yml"
    )) {
      if (file.exists(file_path)) {
        if (any(file.info("render-results.Rmd")$mtime > save_file_info$mtime)) {
          return(TRUE)
        }
      }
    }

    FALSE
  })

  if (should_build_site) {
    save_dir <- dirname(save_file)
    # Remove the prior dir
    unlink(save_dir, recursive = TRUE)
    # Create the new dir
    dir.create(save_dir, showWarnings = FALSE, recursive = TRUE)

    # Build the site
    rmarkdown::render(
      quiet = TRUE,
      "render-results.Rmd",
      # Relative path from input file
      output_file = save_file,
      params = list(
        start_date = cur_date - lubridate::days(days_to_display),
        end_date = cur_date,
        df = sub_df
      ),
      output_options = list(
        # https://github.com/rstudio/rmarkdown/pull/2199
        # lib_dir = file.path(save_dir, "..", "..", "..", "lib")
        lib_dir = file.path(save_dir, "lib")
      )
    )
  }


  # increment and go again
  cur_date <- cur_date - lubridate::days(1)
}

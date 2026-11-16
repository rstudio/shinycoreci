if (Sys.getenv("SHINYCORECI_BOOTSTRAP_PAK") == "true") {
  lib <- Sys.getenv("R_LIBS_USER")
  stopifnot(nzchar(lib))
  dir.create(lib, recursive = TRUE, showWarnings = FALSE)

  options(timeout = max(300, getOption("timeout")))
  repo <- sprintf(
    "https://r-lib.github.io/p/pak/devel/%s/%s/%s",
    .Platform$pkgType, R.Version()$os, R.Version()$arch
  )

  for (attempt in seq_len(3)) {
    tryCatch(
      install.packages("pak", lib = lib, repos = repo),
      error = function(e) message(conditionMessage(e))
    )
    if (requireNamespace("pak", quietly = TRUE, lib.loc = lib)) break
    if (attempt == 3) stop("Could not install pak after three attempts.")
    Sys.sleep(5 * attempt)
  }

  cat("R_LIB_FOR_PAK=", lib, "\n", sep = "", file = Sys.getenv("GITHUB_ENV"), append = TRUE)
}

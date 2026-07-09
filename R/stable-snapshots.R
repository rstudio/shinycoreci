ci_snapshot_state <- new.env(parent = emptyenv())

ci_snapshot_font_dir <- function() {
  dir <- system.file("ci/fonts", package = "shinycoreci")
  if (nzchar(dir)) {
    return(normalizePath(dir, winslash = "/", mustWork = TRUE))
  }

  normalizePath(
    rprojroot::find_package_root_file("inst/ci/fonts"),
    winslash = "/",
    mustWork = TRUE
  )
}

ci_snapshot_font_files <- function() {
  dir <- ci_snapshot_font_dir()
  files <- c(
    sans_regular = "NotoSans-Regular.ttf",
    sans_bold = "NotoSans-Bold.ttf",
    sans_italic = "NotoSans-Italic.ttf",
    sans_bolditalic = "NotoSans-BoldItalic.ttf",
    mono_regular = "NotoSansMono-Regular.ttf",
    mono_bold = "NotoSansMono-Bold.ttf"
  )

  stats::setNames(normalizePath(file.path(dir, files), winslash = "/", mustWork = FALSE), names(files))
}

ci_snapshot_register_fonts <- function() {
  if (!requireNamespace("systemfonts", quietly = TRUE)) {
    return(invisible(FALSE))
  }

  fonts <- ci_snapshot_font_files()
  if (!all(file.exists(fonts))) {
    stop("CoreCI snapshot font files are missing", call. = FALSE)
  }

  sans_aliases <- c(
    "sans",
    "CoreCI Sans",
    "Noto Sans",
    "Arial",
    "Helvetica",
    "Helvetica Neue",
    "Segoe UI",
    "Roboto",
    "Liberation Sans"
  )
  mono_aliases <- c(
    "mono",
    "CoreCI Mono",
    "Noto Sans Mono",
    "Courier",
    "Courier New",
    "Consolas",
    "Menlo",
    "Monaco",
    "Liberation Mono"
  )

  for (alias in sans_aliases) {
    ci_snapshot_register_font(
      alias,
      plain = fonts[["sans_regular"]],
      bold = fonts[["sans_bold"]],
      italic = fonts[["sans_italic"]],
      bolditalic = fonts[["sans_bolditalic"]]
    )
  }

  for (alias in mono_aliases) {
    ci_snapshot_register_font(
      alias,
      plain = fonts[["mono_regular"]],
      bold = fonts[["mono_bold"]],
      italic = fonts[["mono_regular"]],
      bolditalic = fonts[["mono_bold"]]
    )
  }

  invisible(TRUE)
}

ci_snapshot_register_font <- function(alias, plain, bold, italic, bolditalic) {
  tryCatch(
    {
      systemfonts::register_font(
        alias,
        plain = plain,
        bold = bold,
        italic = italic,
        bolditalic = bolditalic
      )
      TRUE
    },
    error = function(e) {
      if (grepl("already exists", conditionMessage(e), fixed = TRUE)) {
        return(FALSE)
      }
      stop(e)
    }
  )
}

ci_snapshot_set_plot_options <- function() {
  opts <- list()
  if (is.null(getOption("shiny.useragg"))) {
    opts[["shiny.useragg"]] <- TRUE
  }
  if (length(opts) > 0) {
    do.call(options, opts)
  }
  invisible(opts)
}

ci_snapshot_font_data_uri <- function(path) {
  raw <- readBin(path, "raw", n = file.info(path)$size)
  paste0("data:font/ttf;base64,", jsonlite::base64_enc(raw))
}

ci_snapshot_css_string <- function(x) {
  paste0("\"", gsub("\"", "\\\\\"", x, fixed = TRUE), "\"")
}

ci_snapshot_font_css <- function() {
  if (!is.null(ci_snapshot_state$font_css)) {
    return(ci_snapshot_state$font_css)
  }

  fonts <- ci_snapshot_font_files()
  font_faces <- function(family, regular, bold, italic = regular, bolditalic = bold) {
    family <- ci_snapshot_css_string(family)
    sprintf(
      paste(
        "@font-face{font-family:%s;font-style:normal;font-weight:400;src:url(%s) format('truetype');}",
        "@font-face{font-family:%s;font-style:normal;font-weight:700;src:url(%s) format('truetype');}",
        "@font-face{font-family:%s;font-style:italic;font-weight:400;src:url(%s) format('truetype');}",
        "@font-face{font-family:%s;font-style:italic;font-weight:700;src:url(%s) format('truetype');}",
        sep = "\n"
      ),
      family,
      ci_snapshot_font_data_uri(regular),
      family,
      ci_snapshot_font_data_uri(bold),
      family,
      ci_snapshot_font_data_uri(italic),
      family,
      ci_snapshot_font_data_uri(bolditalic)
    )
  }

  css <- c(
    font_faces(
      "CoreCI Sans",
      regular = fonts[["sans_regular"]],
      bold = fonts[["sans_bold"]],
      italic = fonts[["sans_italic"]],
      bolditalic = fonts[["sans_bolditalic"]]
    ),
    font_faces(
      "CoreCI Mono",
      regular = fonts[["mono_regular"]],
      bold = fonts[["mono_bold"]]
    )
  )

  ci_snapshot_state$font_css <- paste(css, collapse = "\n")
  ci_snapshot_state$font_css
}

ci_snapshot_inject_browser_fonts <- function(app) {
  css <- ci_snapshot_font_css()
  script <- sprintf(
    paste(
      "(() => {",
      "  if (document.getElementById('ci-snapshot-fonts')) return;",
      "  const style = document.createElement('style');",
      "  style.id = 'ci-snapshot-fonts';",
      "  style.textContent = %s;",
      "  document.head.appendChild(style);",
      "  const generic = /system-ui|-apple-system|BlinkMacSystemFont|Segoe UI|Roboto|Helvetica Neue|Arial|Noto Sans|Liberation Sans|sans-serif|monospace|Menlo|Monaco|Consolas|Courier/i;",
      "  const root = document.documentElement;",
      "  const rootStyle = getComputedStyle(root);",
      "  const setVar = (name, value) => {",
      "    const current = rootStyle.getPropertyValue(name);",
      "    if (!current || generic.test(current)) root.style.setProperty(name, value);",
      "  };",
      "  setVar('--bs-body-font-family', '\"CoreCI Sans\", Arial, sans-serif');",
      "  setVar('--bs-font-sans-serif', '\"CoreCI Sans\", Arial, sans-serif');",
      "  setVar('--bs-font-monospace', '\"CoreCI Mono\", Consolas, monospace');",
      "  if (document.body && generic.test(getComputedStyle(document.body).fontFamily)) {",
      "    document.body.style.fontFamily = '\"CoreCI Sans\", Arial, sans-serif';",
      "  }",
      "})()",
      sep = "\n"
    ),
    jsonlite::toJSON(css, auto_unbox = TRUE)
  )

  try(app$run_js(script), silent = TRUE)
  invisible(app)
}

ci_setup_consistent_snapshots_child <- function() {
  ci_snapshot_register_fonts()
  ci_snapshot_set_plot_options()
  invisible(TRUE)
}

ci_snapshot_merge_shiny_options <- function(options) {
  options <- options %||% list()
  defaults <- list(
    shiny.useragg = TRUE
  )

  utils::modifyList(defaults, options)
}

ci_snapshot_variant <- function(variant = shinytest2::platform_variant()) {
  variant
}

ci_snapshot_app_driver <- function() {
  if (!requireNamespace("shinytest2", quietly = TRUE)) {
    return(NULL)
  }

  app_driver <- shinytest2::AppDriver
  list(
    new = function(...) {
      args <- list(...)
      if (!("variant" %in% names(args))) {
        args$variant <- ci_snapshot_variant()
      } else if (identical(args$variant, shinytest2::platform_variant())) {
        args$variant <- ci_snapshot_variant(args$variant)
      }
      args$options <- ci_snapshot_merge_shiny_options(args$options)
      app <- do.call(app_driver$new, args)
      ci_snapshot_inject_browser_fonts(app)
    }
  )
}

ci_setup_consistent_snapshots_test <- function(env = parent.frame()) {
  ci_snapshot_register_fonts()
  ci_snapshot_set_plot_options()

  app_driver <- ci_snapshot_app_driver()
  if (!is.null(app_driver) && !exists("AppDriver", envir = env, inherits = FALSE)) {
    assign("AppDriver", app_driver, envir = env)
  }

  invisible(TRUE)
}

ci_snapshot_child_profile_expr <- function() {
  paste(
    sprintf(".libPaths(%s)", paste(deparse(.libPaths()), collapse = "")),
    "try(if (requireNamespace('shinycoreci', quietly = TRUE)) utils::getFromNamespace('ci_setup_consistent_snapshots_child', 'shinycoreci')(), silent = TRUE)",
    sep = "\n"
  )
}

ci_snapshot_with_child_profile <- function(app_dir, code) {
  if (is.null(app_dir) || !dir.exists(app_dir)) {
    return(force(code))
  }

  profile <- file.path(app_dir, ".Rprofile")
  profile_exists <- file.exists(profile)
  old_profile <- if (profile_exists) readLines(profile, warn = FALSE) else character()

  on.exit({
    if (profile_exists) {
      writeLines(old_profile, profile, useBytes = TRUE)
    } else {
      unlink(profile)
    }
  }, add = TRUE)

  writeLines(c(old_profile, ci_snapshot_child_profile_expr()), profile, useBytes = TRUE)
  force(code)
}

ci_snapshot_test_setup_expr <- function() {
  "try(if (requireNamespace('shinycoreci', quietly = TRUE)) utils::getFromNamespace('ci_setup_consistent_snapshots_test', 'shinycoreci')(), silent = TRUE)"
}

ci_snapshot_with_test_setup <- function(app_dir, code) {
  setup_dir <- file.path(app_dir, "tests", "testthat")
  if (!dir.exists(setup_dir)) {
    return(force(code))
  }

  setup <- file.path(setup_dir, "setup-zzz-coreci-snapshots.R")
  setup_exists <- file.exists(setup)
  old_setup <- if (setup_exists) readLines(setup, warn = FALSE) else character()

  on.exit({
    if (setup_exists) {
      writeLines(old_setup, setup, useBytes = TRUE)
    } else {
      unlink(setup)
    }
  }, add = TRUE)

  writeLines(c(old_setup, ci_snapshot_test_setup_expr()), setup, useBytes = TRUE)
  force(code)
}

ci_setup_consistent_snapshots <- function() {
  ci_snapshot_register_fonts()
  ci_snapshot_set_plot_options()
  invisible(TRUE)
}

coreci_snapshot_state <- new.env(parent = emptyenv())

coreci_snapshot_font_dir <- function() {
  dir <- system.file("fonts/coreci", package = "shinycoreci")
  if (nzchar(dir)) {
    return(normalizePath(dir, winslash = "/", mustWork = TRUE))
  }

  normalizePath(
    rprojroot::find_package_root_file("inst/fonts/coreci"),
    winslash = "/",
    mustWork = TRUE
  )
}

coreci_snapshot_font_files <- function() {
  dir <- coreci_snapshot_font_dir()
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

coreci_snapshot_register_fonts <- function() {
  if (!requireNamespace("systemfonts", quietly = TRUE)) {
    return(invisible(FALSE))
  }

  fonts <- coreci_snapshot_font_files()
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
    coreci_snapshot_register_font(
      alias,
      plain = fonts[["sans_regular"]],
      bold = fonts[["sans_bold"]],
      italic = fonts[["sans_italic"]],
      bolditalic = fonts[["sans_bolditalic"]]
    )
  }

  for (alias in mono_aliases) {
    coreci_snapshot_register_font(
      alias,
      plain = fonts[["mono_regular"]],
      bold = fonts[["mono_bold"]],
      italic = fonts[["mono_regular"]],
      bolditalic = fonts[["mono_bold"]]
    )
  }

  invisible(TRUE)
}

coreci_snapshot_register_font <- function(alias, plain, bold, italic, bolditalic) {
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

coreci_snapshot_set_plot_options <- function() {
  opts <- list()
  if (is.null(getOption("shiny.useragg"))) {
    opts[["shiny.useragg"]] <- TRUE
  }
  if (is.null(getOption("shiny.usecairo"))) {
    opts[["shiny.usecairo"]] <- FALSE
  }
  if (length(opts) > 0) {
    do.call(options, opts)
  }
  invisible(opts)
}

coreci_snapshot_font_data_uri <- function(path) {
  raw <- readBin(path, "raw", n = file.info(path)$size)
  paste0("data:font/ttf;base64,", jsonlite::base64_enc(raw))
}

coreci_snapshot_css_string <- function(x) {
  paste0("\"", gsub("\"", "\\\\\"", x, fixed = TRUE), "\"")
}

coreci_snapshot_font_css <- function() {
  if (!is.null(coreci_snapshot_state$font_css)) {
    return(coreci_snapshot_state$font_css)
  }

  fonts <- coreci_snapshot_font_files()
  font_faces <- function(family, regular, bold, italic = regular, bolditalic = bold) {
    family <- coreci_snapshot_css_string(family)
    sprintf(
      paste(
        "@font-face{font-family:%s;font-style:normal;font-weight:400;src:url(%s) format('truetype');}",
        "@font-face{font-family:%s;font-style:normal;font-weight:700;src:url(%s) format('truetype');}",
        "@font-face{font-family:%s;font-style:italic;font-weight:400;src:url(%s) format('truetype');}",
        "@font-face{font-family:%s;font-style:italic;font-weight:700;src:url(%s) format('truetype');}",
        sep = "\n"
      ),
      family,
      coreci_snapshot_font_data_uri(regular),
      family,
      coreci_snapshot_font_data_uri(bold),
      family,
      coreci_snapshot_font_data_uri(italic),
      family,
      coreci_snapshot_font_data_uri(bolditalic)
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

  coreci_snapshot_state$font_css <- paste(css, collapse = "\n")
  coreci_snapshot_state$font_css
}

coreci_snapshot_inject_browser_fonts <- function(app) {
  css <- coreci_snapshot_font_css()
  script <- sprintf(
    paste(
      "(() => {",
      "  if (document.getElementById('coreci-snapshot-fonts')) return;",
      "  const style = document.createElement('style');",
      "  style.id = 'coreci-snapshot-fonts';",
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

coreci_snapshot_child_bootstrap <- function() {
  coreci_snapshot_register_fonts()
  coreci_snapshot_set_plot_options()
  invisible(TRUE)
}

coreci_snapshot_merge_shiny_options <- function(options) {
  options <- options %||% list()
  defaults <- list(
    shiny.useragg = TRUE,
    shiny.usecairo = FALSE
  )

  utils::modifyList(defaults, options)
}

coreci_snapshot_child_profile_expr <- function() {
  paste(
    sprintf(".libPaths(%s)", paste(deparse(.libPaths()), collapse = "")),
    "try(if (requireNamespace('shinycoreci', quietly = TRUE)) shinycoreci:::coreci_snapshot_child_bootstrap(), silent = TRUE)",
    sep = "\n"
  )
}

coreci_snapshot_with_child_profile <- function(app_dir, code) {
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

  writeLines(c(old_profile, coreci_snapshot_child_profile_expr()), profile, useBytes = TRUE)
  force(code)
}

coreci_snapshot_patch_shinytest2 <- function() {
  if (!requireNamespace("shinytest2", quietly = TRUE)) {
    return(invisible(FALSE))
  }
  if (isTRUE(coreci_snapshot_state$shinytest2_patched)) {
    return(invisible(TRUE))
  }

  ns <- asNamespace("shinytest2")
  original_start <- get("app_start_shiny", ns)
  patched_start <- function(self, private, ...) {
    coreci_snapshot_with_child_profile(self$get_dir(), {
      original_start(self, private, ...)
    })
  }
  assignInNamespace("app_start_shiny", patched_start, ns = "shinytest2")

  app_driver <- get("AppDriver", ns)
  patched_initialize <- function(...) {
    args <- list(...)
    args$options <- shinycoreci:::coreci_snapshot_merge_shiny_options(args$options)

    do.call(
      get("app_initialize", asNamespace("shinytest2")),
      c(list(self = self, private = private), args)
    )
    shinycoreci:::coreci_snapshot_inject_browser_fonts(self)
    invisible(self)
  }
  app_driver$set("public", "initialize", patched_initialize, overwrite = TRUE)

  coreci_snapshot_state$shinytest2_patched <- TRUE
  invisible(TRUE)
}

coreci_snapshot_bootstrap <- function() {
  coreci_snapshot_register_fonts()
  coreci_snapshot_set_plot_options()
  coreci_snapshot_patch_shinytest2()
  invisible(TRUE)
}

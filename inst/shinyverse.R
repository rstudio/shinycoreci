# Script to produce shinyverse dependency dot graph
# Keeping file as a script to avoid adding unnecessary pkg dependencies

if (FALSE) {

  if (system.file(package = "pak") == "") {
    install.packages("pak", repos = "https://r-lib.github.io/p/pak/dev/")
    pak::pkg_install(c(
      "DiagrammeR",
      "DiagrammeRsvg",
      "purrr",
      "rsvg",
      "ellipsis"
    ))
  }

  # Shiny 1.6.0 usage:
  source(system.file("shinyverse.R", package = "shinycoreci"))
  shinyverse(
    need_to_submit = c(
      "shiny",
      "shinythemes"
    ),
    on_cran = c(
      "bslib",
      "cachem",
      "thematic",
      "shinytest",
      "httpuv",
      "crosstalk",
      "sass",
      "htmlwidgets",
      "htmltools",
      "webdriver",
      "flexdashboard"
    ),
    submit_when_possible = c(
      "promises",
      "later",
      "memoise",
      "fastmap",
      "plumber"
    ),
    pkgs_to_ignore = c(
      "leaflet",
      "leaflet.providers",
      "gt",
      "shinyjster",
      "shinymeta",
      "reactlog",
      "websocket",
      "plotly",
      "pool"
    ),
    extra_txt = "memoise -> cachem; plumber -> httpuv; plumber -> promises"
  )
}




library(DiagrammeR)

shinyverse <- function(
  ...,
  need_to_submit = NULL,
  submitted = NULL,
  on_cran = NULL,
  submit_when_possible = NULL,
  pkgs_to_ignore = NULL,
  extra_txt = NULL,
  legend_pkg = "shinytest",
  save_name = "shinyverse.png"
) {
  ellipsis::check_dots_empty()

  # Save logic. Give error
  if (tools::file_ext(save_name) != "png") stop("File must be png output")

  deps <- pak::pkg_deps("rstudio/shinycoreci", dependencies = TRUE)

  shinycoreci_pkg_deps <-
    setdiff(
      # c("shinycoreci", deps$deps[[1]]$package),
      deps$deps[[1]]$package,

      c(
        "jsonlite", "remotes", "progress", "callr", "renv", "rstudioapi", "Rcpp",
        "httr", "tibble", "sessioninfo", "testthat", "rsconnect", "curl", "english",
        "dplyr", "tidyr", "rmarkdown", "pkgdepends",
        pkgs_to_ignore
      )
    )



  make_node_group <- function(pkgs, color, node_name, label) {
    paste0(
      "{\n",
      "node[fillcolor=\"", color, "\"];\n",
      "\"", node_name, "\" [label=\"", label, "\" shape=rect];\n",
      paste0(
        vapply(pkgs, function(pkg) {
          paste0("\"", pkg, "\";")
        }, character(1)),
        collapse = "\n"
      ),
      "\n}",
      collapse = "\n"
    )
  }

  unaccounted_for <- setdiff(
    shinycoreci_pkg_deps,
    c(need_to_submit, submitted, on_cran, submit_when_possible)
  )
  if (length(unaccounted_for) > 0) {
    stop("Pkgs with no state:\n", paste0("* ", unaccounted_for, "\n"))
  }

  # not_submitting <- shinycoreci_pkg_deps

  groups <- c(
    make_node_group(need_to_submit, "pink", "need_to_submit", "Need to submit"),
    make_node_group(submitted, "gold", "submitted", "Submitted"),
    make_node_group(on_cran, "darkolivegreen2", "on_cran", "On CRAN"),
    make_node_group(submit_when_possible, "lightblue", "submit_later", "Submit when possible"),
    # make_node_group(not_submitting, "grey80", "not_submitting", "Not Submitting"),
    NULL
  )

  legend <- paste0("
{
  rank = same;
  edge[style=invis];

  submit_later ->
  need_to_submit ->
  submitted ->
  on_cran ->
  //not_submitting ->
  imports ->
  suggests ->
  enhances

  imports [label=\"Imports\", style=\"solid\", shape=\"parallelogram\"]
  suggests [label=\"Suggests\", style=\"dashed\", shape=\"parallelogram\"]
  enhances [label=\"Enhances\", style=\"dotted\", shape=\"parallelogram\"]
}
need_to_submit -> \"", legend_pkg, "\" [style=invis]
")

  node_definitions <- Map(
    shinycoreci_pkg_deps,
    f = function(pkg) {
      message("adding node", pkg)
      paste0("\"", pkg, "\"")
    }
  ) %>%
    unlist() %>%
    paste0(";")


  edge_definitions <- Map(
    deps$ref,
    deps$package,
    deps$deps,
    f = function(ref, package, pkg_deps) {
      # if not important, skip
      if (! package %in% shinycoreci_pkg_deps) return(NULL)

      # if no dependencies, skip
      pkg_deps <- pkg_deps[pkg_deps$package %in% shinycoreci_pkg_deps, ]
      if (nrow(pkg_deps) == 0) return(NULL)

      # Add dependencies
      from <- package

      Map(
        pkg_deps$package,
        pkg_deps$type,
        f = function(to, type) {
          dep_type <- switch(
            tolower(type),
            "depends" = "solid",
            "imports" = "solid",
            "linkingto" = "solid",
            "suggests" = "dashed",
            "enhances" = "dotted",
            stop("unknown type: ", type_)
          )

          message("adding edge ", from, " ", to)
          paste0("\"", from, "\" -> \"", to, "\" [style=", dep_type, "]")
        }
      )
    }
  ) %>%
    unlist() %>%
    paste0(";")

  graph_txt <- c(
    'digraph G {

      node[style="filled"];',
    # node_definitions,
    groups,
    legend,
    extra_txt,
    edge_definitions,
    "}"
  ) %>%
    paste0(collapse = "\n")

  graph_txt %T>%
    cat() %>%
    grViz() %>%
    DiagrammeRsvg::export_svg() %>%
    charToRaw() %>%
    rsvg::rsvg() %>%
    png::writePNG(save_name)
}

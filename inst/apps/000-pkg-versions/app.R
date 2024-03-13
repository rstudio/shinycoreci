### Keep this line to manually test this shiny application. Do not edit this line; shinycoreci::::is_manual_app

# TODO-barret; Attempt to preinstall the shinyverse so that all packages are attempted to be installed from the R-Universe

library(shiny)
library(sessioninfo)
library(dplyr)

pkgload::load_all()
pkgs <- shinycoreci:::shinyverse_pkgs
universe_url <- "https://posit-dev-shinycoreci.r-universe.dev"



get_pkg_info <- function(pkg) {
  desc <- packageDescription(pkg)

  get_field <- function(field) {
    if (!is.list(desc)) {
      return(NA_character_)
    }
    val <- desc[[field]]
    if (is.null(val)) {
      return(NA_character_)
    }
    val
  }

  tibble::tibble(
    package = pkg,
    version = get_field("Version"),
    repository = get_field("Repository"),
    packaged = get_field("Packaged"),
    built = get_field("Built"),
    remoteUrl = get_field("RemoteUrl"),
    remoteRef = get_field("RemoteRef"),
    remoteSha = get_field("RemoteSha"),
    remoteType = get_field("RemoteType"),
    remotePkgRef = get_field("RemotePkgRef"),
    remoteRepos = get_field("RemoteRepos"),
    remotePkgPlatform = get_field("RemotePkgPlatform"),
  )
}

dt <- bind_rows(lapply(pkgs, get_pkg_info))


ui <- fluidPage(

  titlePanel("Installed package information"),

  tags$hr(),
  tags$h2("Packages from the shinycoreci universe: "),
  uiOutput("pkg_from_universe"),

  tags$h2("shinyverse packages"),

  verbatimTextOutput("all_pkg_info"),

  # include shinyjster JS at end of UI definition
  shinyjster::shinyjster_js("
    var jst = jster();
    jst.add(Jster.shiny.waitUntilIdle);
    jst.add(function() { Jster.assert.isEqual($('#pkg_from_universe').text(), 'Pass!') });
    jst.test();
  ")

)

server <- function(input, output, session) {

  # include shinyjster_server call at top of server definition
  shinyjster::shinyjster_server(input, output, session)

  output$pkg_from_universe <- renderUI({
    repos <- dt$repository
    repos <- repos[!is.na(repos)]
    repos <- unique(repos)
    all_from_universe <- identical(repos, universe_url)
    if (all_from_universe) {
      tags$h4(tags$span("Pass!", style = "background-color: #7be092;"))
    } else {
      bad_dt <- dt %>% filter(!is.na(repository)) %>% filter(repository != universe_url)
      tagList(
        tags$h4(tags$span("Fail!", style = "background-color: #e68a8a;")),
        tags$ul(
          Map(
            bad_dt$package,
            bad_dt$repository,
            f = function(package, repository) {
              tags$li(tags$code(package), " is from ", repository)
            }
          )
        ),
        tags$h4("Bad packages"),
        verbatimTextOutput("bad_pkg_info")
      )
    }
  })

  output$bad_pkg_info <- renderPrint({
    # pkg_info <- sessioninfo::package_info("installed", include_base = FALSE)

    # pkg_info %>%
    #   dplyr::filter(package %in% pkgs, ) %>%
    #   dplyr::filter
    #   dplyr::select(package, version, loaded, attached, libPath)

    # sub_pkg_info <- pkg_info[pkg_info$package %in% pkgs, ]

    dt %>%
      filter(repository != universe_url) %>%
      print(n = Inf, width = 1000)
  })

  output$all_pkg_info <- renderPrint({
    # pkg_info <- sessioninfo::package_info("installed", include_base = FALSE)

    # pkg_info %>%
    #   dplyr::filter(package %in% pkgs, ) %>%
    #   dplyr::filter
    #   dplyr::select(package, version, loaded, attached, libPath)

    # sub_pkg_info <- pkg_info[pkg_info$package %in% pkgs, ]

    dt %>%
      print(n = Inf, width = 1000)
  })
}

# Create Shiny app ----
shinyApp(ui = ui, server = server)

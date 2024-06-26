library(shiny)
library(bslib)

nav_items <- function(prefix) {
  list(
    nav_panel("a", paste(prefix, ": tab a content")),
    nav_panel("b", paste(prefix, ": tab b content")),
    nav_item(
      tags$a(icon("github"), "Shiny", href = "https://github.com/rstudio/shiny", target = "_blank")
    ),
    nav_spacer(),
    nav_menu(
      "Other links", align = "right",
      nav_panel("c", paste(prefix, ": tab c content")),
      nav_item(
        tags$a(icon("r-project"), "RStudio", href = "https://rstudio.com", target = "_blank")
      )
    )
  )
}



shinyApp(
  page_navbar(
    theme = bs_theme(),
    title = "page_navbar()",
    bg = "#0062cc",
    fillable = FALSE,
    !!!nav_items("page_navbar()"),
    header = markdown("Testing app for `bslib::nav_spacer()` and `bslib::nav_item()` [#319](https://github.com/rstudio/bslib/pull/319)."),
    footer = div(
      style = "width:80%; margin: 0 auto",
      h4("navs_tab()"),
      navset_tab(!!!nav_items("navs_tab()")),
      h4("navs_pill()"),
      navset_pill(!!!nav_items("navs_pill()")),
      h4("navs_tab_card()"),
      navset_card_tab(!!!nav_items("navs_tab_card()")),
      h4("navs_pill_card()"),
      navset_card_pill(!!!nav_items("navs_pill_card()")),
      h4("navs_pill_list()"),
      navset_pill_list(!!!nav_items("navs_pill_list()")),

      # Make sure body height does not change when taking screenshots
      tags$style("body { min-height: 100vh; }"),
    )
  ),
  function(...) { }
)

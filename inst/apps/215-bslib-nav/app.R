### Keep this line to manually test this shiny application. Do not edit this line; shinycoreci::::is_manual_app

library(shiny)
library(bslib)

nav_items <- function(prefix) {
  list(
    nav("a", paste(prefix, ": tab a content")),
    nav("b", paste(prefix, ": tab b content")),
    nav_item(
      tags$a(icon("github"), "Shiny", href = "https://github.com/rstudio/shiny", target = "_blank")
    ),
    nav_spacer(),
    nav_menu(
      "Other links", align = "right",
      nav("c", paste(prefix, ": tab c content")),
      nav_item(
        tags$a(icon("r-project"), "RStudio", href = "https://rstudio.com", target = "_blank")
      )
    )
  )
}





shinyApp(
  page_navbar(
    theme = bs_theme(version = 4),
    title = "page_navbar()",
    bg = "#0062cc",
    !!!nav_items("page_navbar()"),
    header = markdown("Testing app for `bslib::nav_spacer()` and `bslib::nav_item()` [#319](https://github.com/rstudio/bslib/pull/319)."),
    footer = div(
      style = "width:80%; margin: 0 auto",
      h4("navs_tab()"),
      navs_tab(!!!nav_items("navs_tab()")),
      h4("navs_pill()"),
      navs_pill(!!!nav_items("navs_pill()")),
      h4("navs_tab_card()"),
      navs_tab_card(!!!nav_items("navs_tab_card()")),
      h4("navs_pill_card()"),
      navs_pill_card(!!!nav_items("navs_pill_card()")),
      h4("navs_pill_list()"),
      navs_pill_list(!!!nav_items("navs_pill_list()"))
    )
  ),
  function(...) { }
)

library(shinytest2)
library(bslib)

# themes <- list(
#   cosmo4 = list(version = 4, bootswatch = cosmo),
#   cosmo3 = list(version = 3, bootswatch = cosmo)
# )

for (version in c(3,4)) {
  for (theme in c("cosmo")) {
    # Ex: cosmo4
    name <- gsub("\\s+", "-", paste0(theme, version))

    test_that(name, {

      # The bslib themer-demo app listens to this option through
      # bslib::bs_global_get()
      app <- AppDriver$new(
        variant = shinytest2::platform_variant(),
        options = list(
          bslib_theme = bslib::bs_theme(version = version, bootswatch = theme)
        ),
        name = name
      )
      withr::defer({ app$stop() })


      app$expect_values()
      app$expect_screenshot()

      app$set_inputs(`navbar-insert` = "click")
      app$set_inputs(`navbar-insert` = "click")
      app$set_inputs(`tabset-insert` = "click")
      app$set_inputs(`tabset-insert` = "click")
      app$set_inputs(`navlist-insert` = "click")
      app$set_inputs(`navlist-insert` = "click")
      app$set_inputs(`tabset-tabset` = "A")
      app$set_inputs(`navlist-navlist` = "B")
      app$expect_values()
      app$expect_screenshot()

      app$set_inputs(`navlist-remove` = "click")
      app$set_inputs(`tabset-remove` = "click")
      app$set_inputs(`tabset-hide` = "click")
      app$set_inputs(`navbar-remove` = "click")
      app$expect_values()
      app$expect_screenshot()

      app$set_inputs(`navbar-navbar` = "A")
      app$expect_values()
      app$expect_screenshot()
    })

  }
}

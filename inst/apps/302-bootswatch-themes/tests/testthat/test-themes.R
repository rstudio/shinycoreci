library(shinytest2)
library(bslib)

# Only run these tests on mac + r-release
# (To reduce the amount of screenshot diffing noise)
release <- rversions::r_release()$version
release <- paste0(
  strsplit(release, ".", fixed = TRUE)[[1]][1:2],
  collapse = "."
)
if (!identical(paste0("mac-", release), shinytest2::platform_variant())) {
  skip("Not mac + r-release")
}
if (length(dir("_snaps")) > 1) {
  stop("More than 1 _snaps folder found!")
}

themes <-
  list(
    list(version = 5L, bootswatch = "cerulean"),
    list(version = 5L, bootswatch = "cosmo"),
    list(version = 5L, bootswatch = "cyborg"),
    list(version = 5L, bootswatch = "darkly"),
    list(version = 5L, bootswatch = "flatly"),
    list(version = 5L, bootswatch = "journal"),
    list(version = 5L, bootswatch = "litera"),
    list(version = 5L, bootswatch = "lumen"),
    list(version = 5L, bootswatch = "lux"),
    list(version = 5L, bootswatch = "materia"),
    list(version = 5L, bootswatch = "minty"),
    list(version = 5L, bootswatch = "pulse"),
    list(version = 5L, bootswatch = "sandstone"),
    list(version = 5L, bootswatch = "simplex"),
    list(version = 5L, bootswatch = "sketchy"),
    list(version = 5L, bootswatch = "slate"),
    list(version = 5L, bootswatch = "solar"),
    list(version = 5L, bootswatch = "spacelab"),
    list(version = 5L, bootswatch = "superhero"),
    list(version = 5L, bootswatch = "united"),
    list(version = 5L, bootswatch = "yeti"),

    list(version = 4L, bootswatch = "cerulean"),
    list(version = 4L, bootswatch = "cosmo"),
    list(version = 4L, bootswatch = "cyborg"),
    list(version = 4L, bootswatch = "darkly"),
    list(version = 4L, bootswatch = "flatly"),
    list(version = 4L, bootswatch = "journal"),
    list(version = 4L, bootswatch = "litera"),
    list(version = 4L, bootswatch = "lumen"),
    list(version = 4L, bootswatch = "lux"),
    list(version = 4L, bootswatch = "materia"),
    list(version = 4L, bootswatch = "minty"),
    list(version = 4L, bootswatch = "pulse"),
    list(version = 4L, bootswatch = "sandstone"),
    list(version = 4L, bootswatch = "simplex"),
    list(version = 4L, bootswatch = "sketchy"),
    list(version = 4L, bootswatch = "slate"),
    list(version = 4L, bootswatch = "solar"),
    list(version = 4L, bootswatch = "spacelab"),
    list(version = 4L, bootswatch = "superhero"),
    list(version = 4L, bootswatch = "united"),
    list(version = 4L, bootswatch = "yeti")

    # list(version = 3L, bootswatch = "cerulean"),
    # list(version = 3L, bootswatch = "cosmo"),
    # list(version = 3L, bootswatch = "cyborg"),
    # list(version = 3L, bootswatch = "darkly"),
    # list(version = 3L, bootswatch = "flatly"),
    # list(version = 3L, bootswatch = "journal"),
    # list(version = 3L, bootswatch = "lumen"),
    # list(version = 3L, bootswatch = "paper"),
    # list(version = 3L, bootswatch = "readable"),
    # list(version = 3L, bootswatch = "sandstone"),
    # list(version = 3L, bootswatch = "simplex"),
    # list(version = 3L, bootswatch = "slate"),
    # list(version = 3L, bootswatch = "spacelab"),
    # list(version = 3L, bootswatch = "superhero"),
    # list(version = 3L, bootswatch = "united"),
    # list(version = 3L, bootswatch = "yeti")
  )

# ~ 2 mins
pb <- progress::progress_bar$new(
  format = "\n:name [:bar] :current/:total eta::eta\n",
  total = length(themes),
  force = TRUE,
  show_after = 0
)
for (theme in themes) {
  version <- theme$version
  bootswatch <- theme$bootswatch
  name <- paste0(bootswatch, version)

  pb$tick(tokens = list(name = name))

  test_that(paste0("theme: ", name), {

    app <- AppDriver$new(
      name = name,
      variant = shinytest2::platform_variant(),
      seed = 101,
      options = list(
        # The bslib themer-demo app listens to this option through
        # bslib::bs_global_get()
        bslib_theme = bs_theme(
          version = version,
          bootswatch = bootswatch
        )
      )
    )
    withr::defer({ app$stop() })

    app$expect_values()
    app$expect_screenshot()
  })
}

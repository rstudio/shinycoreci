# to be called within `test_shinyjster()`
test_shinyjster_source <- function(apps, args = list()) {

  args$assert <- FALSE
  args$type <- 'lapply'

  ret <- lapply(apps, function(app) {
    callr::r(
      function(app_, ...) {
        cat("shinycoreci - ", "running jster script: ", basename(app_), "\n", sep = "")

        on.exit({
          cat("shinycoreci - ", "stopping jster script: ", basename(app_), "\n", sep = "")
        }, add = TRUE)

        func <- source(file.path(app_, "_shinyjster.R"))$value
        func(app = app_, ...)
      },
      append(
        list(app_ = app),
        args
      ),
      show = TRUE,
      spinner = TRUE
    )
  })

  do.call(rbind, ret)
}


regular_and_source_apps <- function(apps, file = "_shinyjster.R") {

  has_file <- file.exists(file.path(apps, file))

  list(
    regular = apps[!has_file],
    source = apps[has_file]
  )
}

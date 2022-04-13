if (nzchar(system.file(package = "ragg")) &&
    packageVersion("ragg") >= "0.2") {
  shinytest2::test_app()
}

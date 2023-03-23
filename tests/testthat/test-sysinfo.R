test_that("sysinfo can be written", {

    sys_info_file <- tempfile()
    on.exit(unlink(sys_info_file))

    write_sysinfo(sys_info_file)

    expect_true(file.exists(sys_info_file))
    expect_true(file.info(sys_info_file)$size > 0)
})

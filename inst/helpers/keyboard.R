key_press_factory <- function(app) {
  brwsr <- app$get_chromote_session()

  function(
    which = "Tab",
    shift = FALSE,
    command = FALSE,
    control = FALSE,
    alt = FALSE
  ) {
    virtual_code <- switch(
      which,
      Tab = 9,
      Enter = 13,
      Escape = 27,
      ArrowLeft = 37,
      ArrowUp = 38,
      ArrowRight = 39,
      ArrowDown = 40,
      Backspace = 8,
      Delete = 46,
      Home = 36,
      End = 35,
      PageUp = 33,
      PageDown = 34,
      Space = 32
    )

    key <- switch(
      which,
      Space = " ",
      which
    )

    modifiers <- 0
    if (shift) modifiers <- modifiers + 8
    if (command) modifiers <- modifiers + 4
    if (control) modifiers <- modifiers + 2
    if (alt) modifiers <- modifiers + 1

    keydown <- if (!is.null(virtual_code)) {
      brwsr$Input$dispatchKeyEvent(
        "rawKeyDown",
        windowsVirtualKeyCode = virtual_code,
        code = which,
        key = key,
        modifiers = modifiers,
        wait_ = FALSE
      )
    } else {
      brwsr$Input$dispatchKeyEvent(
        "keyDown",
        text = which,
        modifiers = modifiers,
        wait_ = FALSE
      )
    }

    events <-
      keydown$then(function(value) {
        brwsr$Input$dispatchKeyEvent(
          "keyUp",
          windowsVirtualKeyCode = virtual_code,
          code = which,
          key = key,
          modifiers = modifiers,
          wait_ = FALSE
        )
      })

    brwsr$wait_for(events)

    invisible(app)
  }
}

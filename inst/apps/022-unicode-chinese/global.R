if (!file.exists('wqy-zenhei.ttc')) {
  curl::curl_download(
    'https://github.com/rstudio/shiny-examples/releases/download/v0.10.1/wqy-zenhei.ttc',
    'wqy-zenhei.ttc'
  )
}

# On Windows, set locale to Chinese while this app is running
if (.Platform[['OS.type']] == 'windows') {
  old_locale <- Sys.getlocale()
  Sys.setlocale(category = "LC_ALL", locale = "chs")
  # showtext doesn't appear to support CairoPNG on Windows currently
  # https://github.com/yixuan/showtext/issues/35
  opts <- options(shiny.usecairo = FALSE)
  onStop(function() {
    cats <- strsplit(old_locale, ';')[[1]]
    lapply(cats, function(cat) {
      x <- strsplit(cat, '=')[[1]]
      Sys.setlocale(x[1], x[2])
    })
    options(opts)
  })
}

sysfonts::font_add("WenQuanYI Zen Hei", "wqy-zenhei.ttc")
showtext::showtext_auto()
onStop(function() { showtext::showtext_auto(FALSE) })

library(datasets)
rock2 <- rock
names(rock2) <- c("面积", "周长", "形状", "渗透性")



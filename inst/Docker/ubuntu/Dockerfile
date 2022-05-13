# To build, cd to this directory, then:
#   docker build --progress=plain --build-arg GITHUB_PAT=${GITHUB_PAT} -t ghcr.io/rstudio/shinycoreci:base-4.2-focal .
#   docker build --progress=plain --build-arg GITHUB_PAT=${GITHUB_PAT} --build-arg R_VERSION=3.5 -t ghcr.io/rstudio/shinycoreci:base-3.5-bionic .
#   docker build --progress=plain --build-arg GITHUB_PAT=${GITHUB_PAT} --build-arg SHINYCORECI_SHA="shiny-1.4.0.1" -t ghcr.io/rstudio/shinycoreci:base-3.6-bionic-rc_v1.4.0.1 .

#

ARG R_VERSION=4.2

# Not `xenial` because it is EOL
# bionic, focal
ARG RELEASE=focal
FROM rstudio/r-base:${R_VERSION}-${RELEASE}
ARG RELEASE=focal

# MAINTAINER Barret Schloerke "barret@rstudio.com"

# Don't print "debconf: unable to initialize frontend: Dialog" messages
ARG DEBIAN_FRONTEND=noninteractive

## Prep
# texinfo - TeX
# installer - gdebi wget
# cairo device - libcairo2-dev
# libcurl - libcurl4-gnutls-dev
# openssl - libssl-dev
# X11 toolkit intrinsics library - libxt-dev
# markdown - pandoc pandoc-citeproc
# less, vim-tiny - common
# cmake libnlopt-dev pkg-config - nloptr; https://stackoverflow.com/a/39597809/591574
RUN apt-get update && apt-get install -y \
  software-properties-common \
  locales \
  wget \
  apt-utils \
  less \
  vim-tiny \
  texinfo \
  gdebi wget \
  libcairo2-dev \
  libcurl4-gnutls-dev \
  libssl-dev \
  libxt-dev \
  pandoc pandoc-citeproc \
  cmake libnlopt-dev pkg-config

# Create docker user with empty password (will have uid and gid 1000)
RUN useradd --create-home --shell /bin/bash docker \
  && passwd docker -d \
  && adduser docker sudo

RUN locale-gen en_US.utf8 \
  && /usr/sbin/update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8


####
# R
####

# Test
RUN R --version
RUN Rscript --version

####
# RSPM
####


# set up R to point to latest binary cran
RUN mkdir -p '/shinycoreci/R/library' && echo "options(\n\
  repos = c('https://packagemanager.rstudio.com/cran/__linux__/${RELEASE}/latest', 'https://cloud.r-project.org/'),\n\
  download.file.method = 'libcurl',\n\
  # Detect number of physical cores\n\
  Ncpus = parallel::detectCores(logical=FALSE)\n\
  )\n\
  .libPaths('/shinycoreci/R/library')\n\
  " >> `Rscript -e "cat(R.home())"`/etc/Rprofile.site

RUN R -e 'source("https://packagemanager.rstudio.com/__docs__/admin/check-user-agent.R")'

####
# TeX
####

# Install TinyTeX (subset of TeXLive)
# From FAQ 5 and 6 here: https://yihui.name/tinytex/faq/
# Also install ae, parskip, and listings packages to build R vignettes
RUN wget -qO- \
  "https://raw.githubusercontent.com/yihui/tinytex/main/tools/install-unx.sh" | \
  sh -s - --admin --no-path \
  && ~/.TinyTeX/bin/*/tlmgr path add \
  && tlmgr install metafont mfware inconsolata tex ae parskip listings \
  && tlmgr path add \
  && Rscript -e "install.packages('tinytex'); tinytex::r_texmf()"

# This is necessary for non-root users to follow symlinks to /root/.TinyTeX
RUN chmod 755 /root


# =====================================================================
# Shiny Server
# =====================================================================


###
# shinycoreci
###

ARG SHINYCORECI_SHA=HEAD

ARG GITHUB_PAT=NOTSUPPLIED
## Do not persist GITHUB_PAT. Supply it at run time if needed
# # make sure the variable persists
# ENV GITHUB_PAT=$GITHUB_PAT

# pak
RUN R --quiet -e 'install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform[["pkgType"]], R.Version()[["os"]], R.Version()[["arch"]]))'

# Install system requirements of packages
# Install packages using binary builds from package manager
# Install shinycoreci then install shinyverse; Do not install apps deps as they have been installed via binary in prior step
RUN R --quiet \
  -e " \
  pkgs <- c('base64enc', 'bslib', 'Cairo', 'clipr', 'curl', 'dbplyr', 'DiagrammeR', \
  'dplyr', 'DT', 'evaluate', 'flexdashboard', 'future', 'ggplot2', \
  'ggvis', 'hexbin', 'htmltools', 'htmlwidgets', \
  'httpuv', 'jsonlite', 'knitr', 'later', 'leaflet', 'magrittr', \
  'maps', 'markdown', 'memoise', 'networkD3', 'plotly', 'png', \
  'progress', 'promises', 'pryr', 'radiant', 'ragg', 'RColorBrewer', \
  'reactable', 'reactlog', 'reactR', 'rlang', 'rmarkdown', 'rprojroot', \
  'rsconnect', 'RSQLite', 'rversions', 'scales', 'sf', 'shiny', \
  'shinyAce', 'shinydashboard', 'shinyjs', 'shinymeta', \
  'shinytest2', 'shinythemes', 'shinyvalidate', 'showtext', 'sysfonts', \
  'systemfonts', 'testthat', 'thematic', 'tidyr', 'tm', 'websocket', \
  'withr', 'wordcloud', \
  'sessioninfo', \
  'debugme', 'highcharter', 'parsedate', 'quantmod', 'rjson', 'rlist', 'showimage', 'TTR', 'XML', 'xts' \
  ); \
  pak::pkg_system_requirements(pkgs, execute = TRUE); \
  install.packages(pkgs); \
  pak::pkg_install('rstudio/shinycoreci@${SHINYCORECI_SHA}');\
  shinycoreci:::install_shinyverse_local(upgrade = FALSE, install_apps_deps = FALSE);\
  "


###
# Logs
###
COPY retail.c _retail.c
RUN gcc _retail.c -o /usr/bin/retail && chmod +x /usr/bin/retail


###
# Docker
###
EXPOSE 3838

COPY shiny-server.sh /usr/bin/shiny-server.sh

CMD ["/bin/bash", "/usr/bin/shiny-server.sh"]

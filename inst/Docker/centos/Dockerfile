# To build, cd to this directory, then:
#   docker build --progress=plain --build-arg GITHUB_PAT=${GITHUB_PAT} -t ghcr.io/rstudio/shinycoreci:base-4.2-centos7 .


ARG R_VERSION=4.2

# centos7
ARG RELEASE=centos7
FROM rstudio/r-base:${R_VERSION}-${RELEASE}
ARG RELEASE=centos7

# MAINTAINER Barret Schloerke "barret@rstudio.com"

RUN yum -y update && \
  yum -y install epel-release && \
  yum -y groupinstall "Development Tools"

# RUN yum-builddep -y R

# Create docker user with empty password (will have uid and gid 1000)
RUN useradd --create-home --shell /bin/bash docker \
  && passwd docker -d \
  && usermod -a -G wheel docker

# curl - install script below
# vim - nice to have
# gtest - libkml
# expat - gdal
# postgresql - gdal
# proj-* - gdal
# libXt - building R? - remove?
RUN yum -y install \
  curl \
  expat-devel \
  gtest-devel \
  libXt-devel \
  postgresql-devel \
  proj-epsg \
  proj-nad \
  vim

# sf is required by shiny-examples, and requires gdal > 2.0
# gdal-devel centos package is 1.1, so we need to build libkml (a gdal dep, not
# available as package) and then build gdal 2.4.2 ourselves
#
# https://gis.stackexchange.com/questions/263495/how-to-install-gdal-on-centos-7-4/263602
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=667247
RUN curl -L -O https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/libkml/libkml-1.2.0.tar.gz \
  && tar -zxvf libkml-1.2.0.tar.gz \
  && cd libkml-1.2.0 \
  && sed -e '32i#include <unistd.h>' -i src/kml/base/file_posix.cc \
  && sed -e '435,436d' -i third_party/boost_1_34_1/boost/config/suffix.hpp \
  && ./configure --libdir=/usr/lib64 \
  && make -j2 \
  && make install

RUN curl -O https://download.osgeo.org/gdal/2.2.3/gdal-2.2.3.tar.gz \
  && tar -zxvf gdal-2.2.3.tar.gz \
  && cd gdal-2.2.3 \
  && ./configure --libdir=/usr/lib64 --with-libkml --with-geos \
  && make -j2 \
  && make install \
  && echo '/usr/local/lib' >> /etc/ld.so.conf.d/libgdal-x86_64.conf \
  && ldconfig

####
# RSPM
####

# RUN mkdir -p /usr/local/lib64/R/etc
RUN echo "options(repos = c('https://packagemanager.rstudio.com/cran/__linux__/${RELEASE}/latest', 'https://cloud.r-project.org/'), download.file.method = 'libcurl', Ncpus = parallel::detectCores(logical=FALSE) )" >> `Rscript -e "cat(R.home())"`/etc/Rprofile.site
RUN cat `Rscript -e "cat(R.home())"`/etc/Rprofile.site

RUN R -e 'source("https://packagemanager.rstudio.com/__docs__/admin/check-user-agent.R")'

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


###
# shinycoreci
###

# Known deps for shinycoreci
# pak::pkg_system_requirements(pkgs, os = "centos", os_release = "7");
# Removed chrome installation instructions
RUN yum install -y \
  epel-release \
  which \
  make \
  libpng-devel \
  libxml2-devel \
  libcurl-devel \
  openssl-devel \
  zlib-devel \
  freetype-devel \
  fribidi-devel \
  harfbuzz-devel \
  libicu-devel \
  udunits2-devel \
  fontconfig-devel \
  libjpeg-turbo-devel \
  libtiff-devel \
  gdal-devel \
  geos-devel \
  proj-devel \
  proj-epsg \
  cairo-devel \
  glpk-devel \
  gmp-devel \
  pandoc \
  cmake

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
  # NOTE! System requirements must be updated by hand. :-(
  # pak::pkg_system_requirements(pkgs, execute = TRUE); \
  install.packages(pkgs); \
  pak::pkg_install('rstudio/shinycoreci@${SHINYCORECI_SHA}');\
  shinycoreci:::install_shinyverse_local(upgrade = FALSE, install_apps_deps = FALSE);\
  "


# # list the folders to see that it worked
# RUN ls -alh ~ && echo '' &&  ls -alh ~/apps
# # remove radiant as it has a lot of trouble being installed
# RUN rm -r ~/apps/141-radiant

## doesn't work
# COPY retail.c _retail.c
# RUN gcc _retail.c -o /usr/bin/retail
# RUN chmod +x /usr/bin/retail

COPY shiny-server.sh /usr/bin/shiny-server.sh

CMD ["/bin/bash", "/usr/bin/shiny-server.sh"]

RUN yum clean all

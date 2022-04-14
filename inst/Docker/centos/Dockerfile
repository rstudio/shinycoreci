# To build, cd to this directory, then:
#   docker build --build-arg GITHUB_PAT=${GITHUB_PAT} -t rstudio/shinycoreci:base-4.1-centos7 .


ARG R_VERSION=4.1

# centos7
ARG RELEASE=centos7
FROM rstudio/r-base:${R_VERSION}-${RELEASE}
ARG RELEASE=centos7

MAINTAINER Barret Schloerke "barret@rstudio.com"

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
RUN echo "options(repos = c('https://packagemanager.rstudio.com/cran/__linux__/${RELEASE}/latest', 'https://cloud.r-project.org/'),download.file.method = 'libcurl', Ncpus = parallel::detectCores(logical=FALSE))" >> `Rscript -e "cat(R.home())"`/etc/Rprofile.site
RUN cat `Rscript -e "cat(R.home())"`/etc/Rprofile.site

RUN R -e 'source("https://packagemanager.rstudio.com/__docs__/admin/check-user-agent.R")'


###
# shinycoreci
###

# known deps for shinycoreci
RUN yum install -y epel-release glpk-devel gmp-devel libcurl-devel libicu-devel libpng-devel libxml2-devel make openssl-devel pandoc zlib-devel

ARG GITHUB_PAT=NOTSUPPLIED
ENV GITHUB_PAT=$GITHUB_PAT

# prep install
RUN R --quiet -e "install.packages('remotes')"
RUN R --quiet -e "remotes::install_cran(c('knitr', 'rmarkdown', 'curl'))"
RUN R --quiet -e "remotes::install_cran(c('shinytest'))"
# some how this package isn't a dep, but is required for a package
RUN R --quiet -e "remotes::install_cran(c('markdown'))"

ARG SHINYCORECI_SHA=main
ARG APPS_SHA=main

# install testing repo at specific sha
RUN R --quiet -e "remotes::install_github('rstudio/shinycoreci@${SHINYCORECI_SHA}', auth_token ='$GITHUB_PAT')"


###
# shinycoreci-apps
###

# Download the repo in a temp folder, then unzip it into the home folder
RUN mkdir -p /tmp/apps_repo && \
  cd /tmp/apps_repo && \
  wget --no-check-certificate -O _apps.zip https://github.com/rstudio/shinycoreci-apps/archive/${APPS_SHA}.zip && \
  unzip _apps.zip -d . && \
  mv */* ~

# list the folders to see that it worked
RUN ls -alh ~ && echo '' &&  ls -alh ~/apps
# remove radiant as it has a lot of trouble being installed
RUN rm -r ~/apps/141-radiant

# install R pkg system requirements
## Install manually until ragg / RSPM fixes it; https://github.com/r-lib/ragg/issues/41
RUN yum install -y freetype-devel libpng-devel libtiff-devel
# Must use `~/apps` as default working directory is not `~`
RUN R --quiet -e "system(print(shinycoreci::rspm_all_install_scripts('~/apps', release = '${RELEASE}')))"

# install r pkgs
## install htmltools to get dev version
RUN R --quiet -e "remotes::install_github('rstudio/htmltools', auth_token ='${GITHUB_PAT}')"
RUN R --quiet -e "shinycoreci:::update_packages_installed('~/apps')"


## doesn't work
# COPY retail.c _retail.c
# RUN gcc _retail.c -o /usr/bin/retail
# RUN chmod +x /usr/bin/retail

COPY shiny-server.sh /usr/bin/shiny-server.sh

CMD ["/bin/bash", "/usr/bin/shiny-server.sh"]

RUN yum clean all

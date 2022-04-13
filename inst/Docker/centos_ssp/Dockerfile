# To build, cd to this directory, then:
#   docker build --build-arg SSP_LICENSE_FILE="ssp-rstudio-license-2024-09-06.lic" -t rstudio/shinycoreci:ssp-4.1-centos7 .
#
# To run:
#   docker run --rm -p 7979:3838 --name ssp_centos rstudio/shinycoreci:ssp-4.1-centos7

ARG R_VERSION=4.1
ARG RELEASE=centos7
ARG EXTRA_BASE_TAG=
FROM rstudio/shinycoreci:base-${R_VERSION}-${RELEASE}${EXTRA_BASE_TAG}

ARG R_VERSION=4.1
ARG RELEASE=centos7
ARG EXTRA_BASE_TAG=
ARG AWS_BUILD_MACHINE=centos7

RUN yum install -y \
  openssl \
  psmisc

# =====================================================================
# Shiny Server
# =====================================================================

# Download and install shiny server
# https://www.rstudio.com/products/shiny/download-commercial/redhat-centos/
RUN wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-pro-build/${AWS_BUILD_MACHINE}/x86_64/VERSION" -O "version.txt" && \
  VERSION=$(cat version.txt)  && \
  wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-pro-build/${AWS_BUILD_MACHINE}/x86_64/shiny-server-commercial-$VERSION-redhat-x86_64.rpm" -O ss-latest.rpm && \
  yum install -y ss-latest.rpm && \
  rm -f ssp-latest.rpm && \
  rm /srv/shiny-server/index.html

# activate license
ARG SSP_LICENSE_FILE
COPY ${SSP_LICENSE_FILE} ssp.lic
RUN wc -l ssp.lic && \
  /opt/shiny-server/bin/license-manager activate-file ssp.lic > /dev/null 2>&1 && \
  rm ssp.lic

RUN echo "${R_VERSION}-${RELEASE}${EXTRA_BASE_TAG} Shiny Server PRO: `cat version.txt`\n" >> /srv/shiny-server/__version && \
  rm -f version.txt

RUN yum clean all

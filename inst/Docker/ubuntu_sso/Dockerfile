# To build, cd to this directory, then:
#   docker build -t rstudio/shinycoreci:sso-3.6-bionic .
#   docker build --build-arg EXTRA_BASE_TAG="-rc_v1.4.0.1" -t rstudio/shinycoreci:sso-3.6-bionic-rc_v1.4.0.1 .
#
# To run:
#   docker run --rm -p 3838:3838 --name sso_bionic rstudio/shinycoreci:sso-3.6-bionic

ARG R_VERSION=4.1
ARG RELEASE=focal
ARG EXTRA_BASE_TAG=
FROM rstudio/shinycoreci:base-${R_VERSION}-${RELEASE}${EXTRA_BASE_TAG}

ARG R_VERSION=4.1
ARG RELEASE=focal
ARG EXTRA_BASE_TAG=

# =====================================================================
# Shiny Server
# =====================================================================

# Download and install shiny server
ARG AWS_BUILD_MACHINE=ubuntu-14.04
RUN wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/${AWS_BUILD_MACHINE}/x86_64/VERSION" -O "version.txt" && \
  VERSION=$(cat version.txt)  && \
  wget \
    --no-verbose \
    "https://s3.amazonaws.com/rstudio-shiny-server-os-build/${AWS_BUILD_MACHINE}/x86_64/shiny-server-$VERSION-amd64.deb" \
    -O ss-latest.deb && \
  gdebi -n ss-latest.deb && \
  rm -f ssp-latest.deb && \
  rm /srv/shiny-server/index.html

RUN echo "${R_VERSION}-${RELEASE}${EXTRA_BASE_TAG} Shiny Server Open Source: `cat version.txt`\n" >> /srv/shiny-server/__version && \
  rm -f version.txt

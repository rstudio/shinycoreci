# To build, cd to this directory, then:
#   docker build -t ghcr.io/rstudio/shinycoreci:sso-4.2-centos7 .
#
# To run:
#   docker run --rm -p 7878:3838 --name sso_centos ghcr.io/rstudio/shinycoreci:sso-4.2-centos7

ARG R_VERSION=4.2
ARG RELEASE=centos7
ARG EXTRA_BASE_TAG=
FROM ghcr.io/rstudio/shinycoreci:base-${R_VERSION}-${RELEASE}${EXTRA_BASE_TAG}

ARG R_VERSION=4.2
ARG RELEASE=centos7
ARG EXTRA_BASE_TAG=
ARG AWS_BUILD_MACHINE=centos6.3


# =====================================================================
# Shiny Server
# =====================================================================

# Download and install shiny server
RUN wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/${AWS_BUILD_MACHINE}/x86_64/VERSION" -O "version.txt" && \
  VERSION=$(cat version.txt)  && \
  wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/${AWS_BUILD_MACHINE}/x86_64/shiny-server-$VERSION-x86_64.rpm" -O ss-latest.rpm && \
  yum install -y ss-latest.rpm && \
  rm -f ssp-latest.rpm && \
  rm /srv/shiny-server/index.html





RUN echo "${R_VERSION}-${RELEASE}${EXTRA_BASE_TAG} Shiny Server Open Source: `cat version.txt`\n" >> /srv/shiny-server/__version && \
  rm -f version.txt


RUN yum clean all

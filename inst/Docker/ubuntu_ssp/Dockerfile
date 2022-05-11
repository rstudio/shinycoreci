# To build, cd to this directory, then:
#   docker build --progress=plain -t ghcr.io/rstudio/shinycoreci:ssp-4.2-focal .
#   docker build --build-arg EXTRA_BASE_TAG=-rc_v1.4.0.1 -t rstudio/shinycoreci:ssp-4.2-focal-rc_v1.4.0.1 .

# -v /local/path/to/file1:/container/path/to/file.txt

# To run:
#   docker run --rm -p 4949:3838 -v license:/opt/license --name ssp_focal ghcr.io/rstudio/shinycoreci:ssp-4.2-focal
#   docker run --rm -p 4949:3838 -v license:/opt/license --name ssp_bionic ghcr.io/rstudio/shinycoreci:ssp-4.2-bionic
#   docker run --rm -p 4949:3838 --name ssp_focal rstudio/shinycoreci:ssp-4.2-focal-rc_v1.4.0.1

ARG R_VERSION=4.2
ARG RELEASE=focal
ARG EXTRA_BASE_TAG=
FROM ghcr.io/rstudio/shinycoreci:base-${R_VERSION}-${RELEASE}${EXTRA_BASE_TAG}

ARG R_VERSION=4.2
ARG RELEASE=focal
ARG EXTRA_BASE_TAG=

# =====================================================================
# Shiny Server
# =====================================================================

# https://www.rstudio.com/products/shiny/download-commercial/ubuntu/
# RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
RUN apt-get install -y gdebi-core && \
  case "${RELEASE}" in \
    xenial) AWS_BUILD_MACHINE=ubuntu-16.04 ;; \
    *)      AWS_BUILD_MACHINE=ubuntu-18.04 ;; \
  esac && \
  wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-pro-build/${AWS_BUILD_MACHINE}/x86_64/VERSION" -O "version.txt" && \
  VERSION=$(cat version.txt)  && \
  echo "Version: $VERSION" && \
  wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-pro-build/${AWS_BUILD_MACHINE}/x86_64/shiny-server-commercial-$VERSION-amd64.deb" -O ssp-latest.deb && \
  gdebi -n ssp-latest.deb && \
  rm -f ssp-latest.deb && \
  rm /srv/shiny-server/index.html


RUN echo "${R_VERSION}-${RELEASE}${EXTRA_BASE_TAG} Shiny Server PRO: `cat version.txt`\n" >> /srv/shiny-server/__version && \
  rm -f version.txt

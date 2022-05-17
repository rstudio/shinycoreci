# To build, cd to this directory, then:
#   docker build --progress=plain -t centos_debug .

ARG R_VERSION=4.2

# centos7
ARG RELEASE=centos7
FROM rstudio/r-base:${R_VERSION}-${RELEASE}
ARG RELEASE=centos7

RUN yum -y update && \
  yum -y install epel-release && \
  yum -y groupinstall "Development Tools"

# Create docker user with empty password (will have uid and gid 1000)
RUN useradd --create-home --shell /bin/bash docker \
  && passwd docker -d \
  && usermod -a -G wheel docker

####
# RSPM
####

# RUN mkdir -p /usr/local/lib64/R/etc
RUN echo "options(repos = c('https://packagemanager.rstudio.com/cran/__linux__/${RELEASE}/latest', 'https://cloud.r-project.org/'), download.file.method = 'libcurl', Ncpus = parallel::detectCores(logical=FALSE) )" >> `Rscript -e "cat(R.home())"`/etc/Rprofile.site
RUN R -e 'source("https://packagemanager.rstudio.com/__docs__/admin/check-user-agent.R")'

# pak
RUN R --quiet -e 'install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform[["pkgType"]], R.Version()[["os"]], R.Version()[["arch"]]))'

# Install system requirements of packages
# Install packages using binary builds from package manager
# Install shinycoreci then install shinyverse; Do not install apps deps as they have been installed via binary in prior step
RUN R --quiet \
  -e " \
  pkgs <- c('shiny'); \
  pak::pkg_system_requirements(pkgs, execute = TRUE); \
  install.packages(pkgs); \
  "

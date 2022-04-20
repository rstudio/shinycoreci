# To build, cd to this directory, then:
#   docker build --progress=plain --build-arg GITHUB_PAT=${GITHUB_PAT} -t rstudio/shinycoreci:base-4.1-focal .
#   docker build --progress=plain --build-arg GITHUB_PAT=${GITHUB_PAT} --build-arg R_VERSION=3.5 -t rstudio/shinycoreci:base-3.5-bionic .
#   docker build --progress=plain --build-arg GITHUB_PAT=${GITHUB_PAT} --build-arg SHINYCORECI_SHA="shiny-1.4.0.1" -t rstudio/shinycoreci:base-3.6-bionic-rc_v1.4.0.1 .

#

ARG R_VERSION=4.1

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
  pandoc pandoc-citeproc

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

# ARG SHINYCORECI_SHA=HEAD
ARG SHINYCORECI_SHA=docker_new

# Do not persist GITHUB_PAT. Supply it at run time as well
ARG GITHUB_PAT=NOTSUPPLIED
# # make sure the variable persists
# ENV GITHUB_PAT=$GITHUB_PAT

# pak
RUN R --quiet -e 'install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform[["pkgType"]], R.Version()[["os"]], R.Version()[["arch"]]))'

# Make sure pak is the latest version
# RUN R --quiet -e "pak::pak_update()"
# install testing repo at specific sha
RUN R --quiet \
  -e " \
    # Install troublesome packages\n\
    pak::pkg_install('networkD3'))\n\
    pak::pkg_install(c('rstudio/shinycoreci@${SHINYCORECI_SHA}', 'networkD3'))\n\
    shinycoreci:::install_shinyverse_local(upgrade = FALSE)\n\
    "

###
# shinycoreci apps
###

# # remove radiant as it has a lot of trouble being installed
# RUN rm -r ~/apps/141-radiant

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

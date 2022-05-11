FROM rstudio/r-base:4.2-focal

ARG DEBIAN_FRONTEND=noninteractive

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
RUN mkdir -p '/barret/R/library' && echo "options(\n\
  repos = c('https://packagemanager.rstudio.com/cran/__linux__/focal/latest', 'https://cloud.r-project.org/')\n\
  )\n\
  .libPaths('/barret/R/library')\n\
  " >> `Rscript -e "cat(R.home())"`/etc/Rprofile.site

RUN R -e 'source("https://packagemanager.rstudio.com/__docs__/admin/check-user-agent.R")'


###
# Test packages
###

# # Show that igraph can be installed from binary
# RUN R --quiet -e "install.packages('networkD3')"
# # Remove networkD3 and igraph
# RUN R --quiet -e "remove.packages(c('networkD3', 'igraph'))"

# Install using pak
RUN R --quiet -e 'install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform[["pkgType"]], R.Version()[["os"]], R.Version()[["arch"]]))'
RUN R --quiet -e "pak::pkg_install('networkD3')"

% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sysinfo.R
\name{base_packages}
\alias{base_packages}
\title{Return names of packages included with R}
\usage{
base_packages()
}
\description{
Some installed packages have a Priority of "base" or "recommended".
Shouldn't try to upgrade these packages with \code{remotes::install_cran}
because it will fail.
}

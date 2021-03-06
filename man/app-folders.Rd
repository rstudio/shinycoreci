% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/apps.R
\name{apps_manual}
\alias{apps_manual}
\alias{apps_shinytest}
\alias{apps_shinyjster}
\alias{apps_testthat}
\alias{apps_runtests}
\alias{apps_deploy}
\title{Get names of Shiny apps to be tested}
\usage{
apps_manual(dir)

apps_shinytest(dir)

apps_shinyjster(dir)

apps_testthat(dir)

apps_runtests(dir, filter = NULL)

apps_deploy(dir)
}
\arguments{
\item{dir}{base directory to look for shiny applications}

\item{filter}{regex to run on file name in the \verb{./tests} directory}
}
\description{
All \code{apps_*} methods inspect each application to determine if if testing is possible.
}
\section{Functions}{
\itemize{
\item \code{apps_manual}: App folders that are to be manually tested.

\item \code{apps_shinytest}: App folders that contain a \verb{shinytest.R} file

\item \code{apps_shinyjster}: App folders that contain the text \code{shinyjster} in a Shiny R file

\item \code{apps_testthat}: App folders that contain a \verb{testthat.R} file

\item \code{apps_runtests}: App folders that contain a \verb{./tests} directory

\item \code{apps_deploy}: App folders that contain a any Shiny app file
}}


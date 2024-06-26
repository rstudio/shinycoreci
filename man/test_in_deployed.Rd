% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/test-in-connect.R, R/test-in-shinyapps_io.R
\name{test_in_connect}
\alias{test_in_connect}
\alias{test_in_shinyappsio}
\title{Test deployed apps}
\usage{
test_in_connect(type = c("manual", "all"))

test_in_shinyappsio(type = c("manual", "all"))
}
\arguments{
\item{type}{Type of apps to test. \code{"manual"} (default) will only contain apps
that should be manually tested. \code{"all"} will contain all apps that have
been deployed. This is every app except for \code{141-radiant}.}
}
\description{
Opens an app on the hosted server and runs silbing apps in an iframe.
}
\section{Functions}{
\itemize{
\item \code{test_in_connect()}: Test deployed applications on RStudio Connect

\item \code{test_in_shinyappsio()}: Test connect applications given the server and account

}}
\examples{
\dontrun{test_in_connect()}
\dontrun{test_in_test_in_shinyapps_io()}
}

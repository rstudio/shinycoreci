% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/docker.R
\name{docker_clean}
\alias{docker_clean}
\title{Clean up docker files}
\usage{
docker_clean(stopped_containers = TRUE, untagged_images = TRUE)
}
\arguments{
\item{stopped_containers}{boolean that determines if all stopped containers should be removed}

\item{untagged_images}{boolean that determines of all untagged images should be removed}
}
\description{
Clean up docker files
}

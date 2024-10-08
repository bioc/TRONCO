% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/as.functions.R
\name{as.description}
\alias{as.description}
\title{as.description}
\usage{
as.description(x)
}
\arguments{
\item{x}{A TRONCO compliant dataset.}
}
\value{
The description annotating the dataset, if any.
}
\description{
Return the description annotating the dataset, if any. Input 'x' should be
a TRONCO compliant dataset - see \code{is.compliant}.
}
\examples{
data(test_dataset)
as.description(test_dataset)

}

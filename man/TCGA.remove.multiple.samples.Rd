% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/external.R
\name{TCGA.remove.multiple.samples}
\alias{TCGA.remove.multiple.samples}
\title{TCGA.remove.multiple.samples}
\usage{
TCGA.remove.multiple.samples(x)
}
\arguments{
\item{x}{A TRONCO compliant dataset.}
}
\value{
A TRONCO compliant dataset
}
\description{
If there are multiple sample in x, according to TCGA barcodes naming, remove them
}
\examples{
data(test_dataset)
TCGA.remove.multiple.samples(test_dataset)

}

% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/editing.functions.R
\name{delete.gene}
\alias{delete.gene}
\title{delete.gene}
\usage{
delete.gene(x, gene)
}
\arguments{
\item{x}{A TRONCO compliant dataset.}

\item{gene}{The name of the gene to delete.}
}
\value{
A TRONCO complian dataset.
}
\description{
Delete a gene
}
\examples{
data(test_dataset)
test_dataset = delete.gene(test_dataset, 'TET2')

}

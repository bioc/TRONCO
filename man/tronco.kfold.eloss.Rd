% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/statistics.R
\name{tronco.kfold.eloss}
\alias{tronco.kfold.eloss}
\title{tronco.kfold.eloss}
\usage{
tronco.kfold.eloss(
  x,
  models = names(as.models(x)),
  runs = 10,
  k = 10,
  silent = FALSE
)
}
\arguments{
\item{x}{A reconstructed model (the output of tronco.capri or tronco.caprese)}

\item{models}{The names of the selected regularizers (bic, aic or caprese)}

\item{runs}{a positive integer number, the number of times cross-validation will be run}

\item{k}{a positive integer number, the number of groups into which the data will be split}

\item{silent}{A parameter to disable/enable verbose messages.}
}
\description{
Perform a k-fold cross-validation using the function bn.cv
to estimate the entropy loss. For details and examples 
regarding the statistical assesment of an inferred model, 
we refer to the Vignette Section 7.
}
\examples{
data(test_model)
tronco.kfold.eloss(test_model, k = 2, runs = 2)

}

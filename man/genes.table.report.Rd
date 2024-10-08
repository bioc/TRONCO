% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/visualization.R
\name{genes.table.report}
\alias{genes.table.report}
\title{genes.table.report}
\usage{
genes.table.report(
  x,
  name,
  dir = getwd(),
  maxrow = 33,
  font = 10,
  height = 11,
  width = 8.5,
  fill = "lightblue",
  silent = FALSE
)
}
\arguments{
\item{x}{A TRONCO compliant dataset.}

\item{name}{filename}

\item{dir}{working directory}

\item{maxrow}{maximum number of row per page}

\item{font}{document fontsize}

\item{height}{table height}

\item{width}{table width}

\item{fill}{fill color}

\item{silent}{A parameter to disable/enable verbose messages.}
}
\value{
LaTEX code
}
\description{
Generate PDF and laex tables
}

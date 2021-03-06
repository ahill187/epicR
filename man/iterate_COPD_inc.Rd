% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/iterative-incidence.R
\name{iterate_COPD_inc}
\alias{iterate_COPD_inc}
\title{Solves stochastically for COPD incidence rate equation.}
\usage{
iterate_COPD_inc(nIterations = 500, nPatients = 1e+05, time_horizon = 20)
}
\arguments{
\item{nIterations}{number of iterations for the numberical solution}

\item{nPatients}{number of simulated agents.}

\item{time_horizon}{in years}
}
\value{
regression co-efficients as files
}
\description{
Solves stochastically for COPD incidence rate equation.
}

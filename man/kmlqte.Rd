% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/kmlqte.R
\name{kmlqte}
\alias{kmlqte}
\title{Kaplan-Meier Local Quantile Treatment Effect}
\usage{
kmlqte(out, delta, treat, z, xpscore, probs = 0.5, b = 1000, ci = c(0.9,
  0.95, 0.99), cores = 1, monot = TRUE)
}
\arguments{
\item{out}{vector containing the outcome of interest}

\item{delta}{vector containing the censoring indicator (1 if observed, 0 if censored)}

\item{treat}{vector containing the treatment indicator (1 if treated, 0 if control)}

\item{z}{vector containing the binary instrument}

\item{xpscore}{matrix (or data frame) containing the covariates (and their
transformations) to be included in the instrument propensity score estimation.
Instrument Propensity score estimation is based on Logit.}

\item{probs}{scalar or vector of probabilities with values in (0,1) for which
the quantile treatment effect is computed. Default is 0.5, returning
the median.}

\item{b}{The number of bootstrap replicates to be performed. Default is 1,000.}

\item{ci}{A scalar or vector with values in (0,1) containing the confidence level(s)
of the required interval(s). Default is a vector with
0,90, 0.95 and 0.99}

\item{cores}{number of processesors to be used during the bootstrap (default is 1).
If cores>1, the bootstrap is conducted using snow.}

\item{monot}{Default is TRUE, which impose that the estimated counterfactual distributions are in
proper CDF's, i.e. takes values between [0,1], and are non-decreasing.
Boundedness is imposed by truncantion, and monotonicity is imposed using the
rearrangement procedure proposed by Chernozhukov, Fernandez-Val, and Galichon (2010),
implemented in R through package Rearrangement. If FALSE, no adjustment is made.}
}
\value{
a list containing the local quantile treatment effect estimate, lqte,
       and the bootstrapped \emph{ci} confidence
       confidence interval, lqte.lb (lower bound), and lqte.ub (upper bound).
}
\description{
\emph{kmlqte} computes the Local Quantile Treatment Effect for possibly right-censored outcomes.
The estimator relies on the availability of an Instrumental variable Z, and on a monotonicity assumption.
To implement the estimator, we make use of an instrumental propensity score approach.
For details of the estimation procedure, see Sant'Anna (2016a), 'Program Evaluation with
Right-Censored Data'.
}


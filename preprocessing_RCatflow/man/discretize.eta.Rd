\name{discretize.eta}
\alias{discretize.eta}

\title{
Make vertical discretization
}
\description{
Internal function of the CATFLOW package to compute vertical discretization (eta vector) 
with fine resolution at simulated macropores +- steps
}
\usage{
discretize.eta(relfak, endmac, steps = 1, max.dist, dimfak, reg = T, top = 1:3)
}

\arguments{
  \item{relfak}{
Multiplier matrix from macropore simulations
}
  \item{endmac}{
Vector with lowest position (row number) of macropores
}
  \item{steps}{
Step size for discretization next to macropore endings
}
  \item{max.dist}{
Maximum seperation of simulation nodes [no. rows]
}
  \item{dimfak}{
Fraction of dimension to compute missing \code{max.dist} (default 5.0\%)
}
  \item{reg}{
Flag for generating a regular grid using \code{max.dist}
}
  \item{top}{
Vector of nodes at upper boundary which should keep a finer discretization
}
}

\value{
A vector of vertical discretization.
}
\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}
\seealso{
\code{\link{discretize.mak}}, \code{\link{discretize.rect}}, \code{\link{discretize.pipe}}
}

\keyword{internal}

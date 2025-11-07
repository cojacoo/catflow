\name{discretize.xsi}
\alias{discretize.xsi}

\title{
Make lateral discretization
}
\description{
Internal function of the CATFLOW package to compute lateral discretization (xsi vector) 
with fine resolution at simulated macropores +- steps
}
\usage{
discretize.xsi(relfak, steps = 1, max.dist, dimfak, reg = TRUE)
}

\arguments{
  \item{relfak}{
Multiplier matrix from macropore simulations
}
  \item{steps}{
Step size for discretization next to macropores [no. of columns]
}
  \item{max.dist}{
Maximum seperation of simulation nodes [no. columns]
}
  \item{dimfak}{
Fraction of dimension to compute missing \code{max.dist} (default 2.5\%)
}
  \item{reg}{
Flag for generating a regular grid using \code{max.dist}
}
}

\value{
A vector of lateral discretization.
}
\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}
\seealso{
\code{\link{discretize.mak}}, \code{\link{discretize.rect}}, \code{\link{discretize.pipe}}
}

\keyword{internal}

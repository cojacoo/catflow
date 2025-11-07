\name{read.catf.resultmat}
\alias{read.catf.resultmat}

\title{
Read a single result file in matrix form
}
\description{
Reads a single CATFLOW result file in matrix form.
}
\usage{
read.catf.resultmat(resultfile)
}

\arguments{
  \item{resultfile}{
Name (and path) of the result file 
}
}

\details{
The function \code{read.catf.resultmat} is used to read a CATFLOW result file with system 
state variables at different timesteps, i.e., a sequence of matrices.

Sometimes there were problems with long exponents in the CATFLOW result files, for example
'0.605e-123' was printed as '-0.605-123' in the results file. The function tries to 
correct for this bug, however, if not sucussful, the faulty entry is replaced by NA. In either
case, a warning indicating the ambiguous entries is displayed, and a second warning if NAs were
produced.
}

\value{
A list with two components:
 \item{val }{named list with matrices of CATFLOW results; the hillslope ID given in the result file is used as a name}
 \item{time }{vector of same length as \code{val} with the simulation times for each result matrix}

 In case of several hillslopes, a list is returned that contains one list as described above per hillslope, the hillslope ID given in the result file is used as a name.
}
\references{
Maurer, T. and E. Zehe (2007) \emph{CATFLOW User Guide and Program Documentation (Version Catstat)}
}
\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}


\seealso{
\code{\link{read.catf.results}}
}

\examples{
  ## TODO
  # PROBLEM: result file needed
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ utilities}

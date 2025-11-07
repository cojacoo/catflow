\name{read.surfrun.out}
\alias{read.surfrun.out}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Read CATFLOW surface runoff output
}
\description{
Reads a surface runoff output file from a CATFLOW simulation.
}
\usage{
read.surfrun.out(filename)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{filename}{
Name (and path) of an surface runoff output file to read 
}
}

\value{
A list with the following items:
 \item{orig }{Simulated surface runoff in original format: Time in s, rain in m/s, runoff in m^3/s and m^3, respectively}
 \item{converted }{Simulated surface runoff multiplied with the conversion factors specified in header: Time in d, rain in mm/h, runoff in mm/h and mm, respectively} 
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
### TO DO ###
## problem: file to read ##
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{utilities}


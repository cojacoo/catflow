\name{use.psi.fin}
\alias{use.psi.fin}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Read final matric potential file and write new ini-files
}
\description{
Reads the final state of soil matric potential (psi.fin) from a Catflow simulation and generates new initial conditions from this state for a subsequent simulation.
}
\usage{
use.psi.fin(resultfile, inidir, ininame, make.newini= TRUE)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{resultfile}{
Name of file with final matric potential
}
  \item{inidir}{
Name of directory for the initial condition files
}
  \item{ininame}{
Pattern for naming the initial condition files (any '.ini' suffix is possibly removed)
}
  \item{make.newini}{
Logical whether new ini-files are to be generated; defaults to 'TRUE'.
}
}
\details{
The function 'use.psi.fin' is used to specify initial conditions from the output of an earlier simulation with CATFLOW. 
The new files with the initial conditions are written to the specified directory, using the 'ininame' string and the hillslope number as a name (in case of several hillslopes; otherwise, only the 'ininame' is used).
}
\value{
A list with the final matric potential of each hillslope in matrix form is returned invisibly.
}
\references{
Maurer, T. and E. Zehe (2007) \emph{CATFLOW User Guide and Program Documentation (Version Catstat)}
}
\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}
\note{
%%  ~~further notes~~
}

%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{
\code{\link{write.facmat}}, which is used to write the ini-files
}
\examples{
  ### jw example file
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ utilities }


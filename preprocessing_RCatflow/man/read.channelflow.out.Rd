\name{read.channelflow.out}
\alias{read.channelflow.out}

\title{
Read CATFLOW channel flow output
}
\description{
Reads a channel flow output file from a CATFLOW simulation.
}
\usage{
read.channelflow.out(filename, plotting = T)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{filename}{
  Name (and path) of an evapo-transpiration file to read 
}
  \item{plotting}{
Logical if the simulation results should be plotted.
}
}
\details{
%%  ~~ If necessary, more details than the description above ~~
}
\value{
A list with the following items:
 \item{orig}{Simulated channel flow in complete and original format(time in seconds, cumulative runoff in cubic meters)}
 \item{converted}{Simulated channel flow with time in days and runoff in liters per second}
%% ...
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
\code{\link{read.catf.results}}
}
\examples{

#### FILE does not exist yet
\dontrun{
        example.channelflow <- read.channelflow.out(file.path(.libPaths(), "Catflow", "Catflow-TEST", "out", "gang.out") ) 
 }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ utilities}

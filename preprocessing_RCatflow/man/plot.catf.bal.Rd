\name{plot.catf.bal}
\alias{plot.catf.bal}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Plot a CATFLOW simulation balance
}
\description{
Plots the water balance of a CATFLOW simulation, and calculate the total balance.  
}
\usage{
plot.catf.bal(bilanz, interact = TRUE, ylim, stay, ...)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{bilanz}{
Data frame with balance file results from CATFLOW, or a balance file name (and path)
}
  \item{interact}{
Logical to indicate if used interactively
}
  \item{ylim}{
Limits for the y-axis (optional)
}
  \item{stay}{
Logical to indicate if the graphics window should stay at the front of the window stack (optional)
}
  \item{\dots}{
Arguments to be passed to plot methods, such as graphical parameters (see \code{par}).  
For example, \code{main = "Title"} to specify a title for the plot.
}
}
\details{
The function \code{plot.catf.bal} is mainly used for its side-effect of plotting a
CATFLOW balance file. The input may be given either as a data frame, e.g., from 
\code{read.catf.balance}, or a character string with the filename of a CATFLOW balance file.

The columns selected for plotting are: Precipitation, surface runoff, 
right and lower boundary fluxes, soil moisture, sinks and transpiration.


If assigned, a data frame with simulation time and total 
balance is returned. The total balance is calculated as:

\eqn{total = precipitation - soil moisture - surface runoff - soil evaporation - interception + sinks + lower boundary flux + right boundary flux}
}
\value{
A data frame with simulation time and total balance
}
\references{
Maurer, T. and E. Zehe (2007) \emph{CATFLOW User Guide and Program Documentation (Version Catstat)}
}
\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}
\seealso{
\code{\link{read.catf.balance}}
}

\examples{
### TO DO ###
## problem: file to read ##
\dontrun{
bla <- plot.catf.bal("F:/CATF/Projekte/Code_test/min.surf.run/out/bilanz.csv") 
}
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{utilities}


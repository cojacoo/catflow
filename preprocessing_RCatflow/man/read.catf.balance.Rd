\name{read.catf.balance}
\alias{read.catf.balance}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Read CATFLOW balance file
}
\description{
Reads a balance output file from a CATFLOW simulation.
}
\usage{
read.catf.balance(res.path, balance.file="bilanz.csv", 
                  differences = FALSE, plottin = FALSE, col.no, ...)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{res.path}{
Path of the balance file to read (may include the filename) 
}
 \item{balance.file}{
Filename of the balance file to read 
}
  \item{differences}{
Logical if differenced balance data should be returned
}
  \item{plottin}{
Logical if plotting should be done
}
  \item{col.no}{
Number(s) of columns to plot (optional)
}
  \item{\dots}{
Arguments to be passed to plot methods, such as graphical parameters (see \code{par}).  
}
}
\details{
The function \code{read.catf.balance} reads the CATFLOW balance file specified by \code{res.path} and \code{balance.file}. 
If \code{res.path} is missing, the current working dir is searched for the file. If a filename with ending ".csv" is included in \code{res.path}, then \code{balance.file} is ignored.


If desired (\code{differences = TRUE}), the simulation results (not time) are returned in
differenced form, otherwise they are returned in original cumulative format.

If desired (\code{plottin = TRUE}), the simulation results are plotted against time. 
Plotting of selected variables is possible by specifiying a range of column numbers
\code{col.no}, commonly starting with 4. This only works if the balance file contains the results for a single hillslope.
}
\value{
A data frame with the contents of the CATFLOW balance file;
in differenced form with \code{differences = TRUE}.
In case several slopes were simulated, a list with data frames, one for each slope, is returned.
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

 \dontrun{
        example.balance <- read.catf.balance(file.path(.libPaths(), "Catflow", "Catflow-TEST", "out", "bilanz.csv"),
                                  plottin = T,  differences=T, cex=0.7) 
 }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{utilities}


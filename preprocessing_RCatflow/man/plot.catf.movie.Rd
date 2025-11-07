\name{plot.catf.movie}
\alias{plot.catf.movie}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Plot CATFLOW results sequently 
}
\description{
Plots the results of a CATFLOW simulation for a hillslope profile in chronological
sequence, either on the screen or to a pdf file.

}
\usage{
plot.catf.movie(resultmat, geof, 
                sel, begindate, outputPath, filename, 
                SCREENPLOT = TRUE, delayTime = 0.1, ...)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{resultmat}{
List with a list of simulated values and a vector of simulation times,
e.g., read with \code{read.catf.resultmat}.
}
  \item{geof}{
Simulation geometry as a list with the components \code{hko} and \code{sko}, which
are the matrices of local vertical and horizontal coordinates, respectively. 
These are for example returned by \code{read.geofile}.
}
  \item{sel}{
Vector for selection of columns to plot (optional).
}
  \item{begindate}{
Start date given as a suitable date-time object, or date string in the format "\%d.\%m.\%Y \%H:\%M:\%S" for labelling the plots.
If missing, the simulation time is used as title.
}
  \item{SCREENPLOT}{
Logical if plotting should occur on the screen (TRUE), or to a pdf file.
}
  \item{delayTime}{
Delay time between subsequent plot when plotting on the screen.
}
  \item{outputPath}{
Path for output when plotting to a file (optional).
}
  \item{filename}{
Name for pdf file when plotting to a file; with or without extension.
}
  \item{\dots}{
Further arguments for color-coding of the values, see \code{\link{color.codes}}.
}
}
\details{
The function \code{plot.catf.movie} is used for its side-effect: generating a 
chronological sequence of plots to visualise CATFLOW results.
The plots are either displayed on the screen (if \code{SCREENPLOT = TRUE}, or saved
as a pdf file.


If \code{begindate} is missing, the simulation time in seconds is used in the title.

If \code{filename} is missing, the simulation results are plotted on the screen only.
If \code{outputPath} is missing, the current directory is used.
 
}
\value{
No value is returned.
}

\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}

\seealso{
\code{\link{read.geofile}}, \code{\link{read.catf.resultmat}},
\code{\link{color.codes}}, \code{\link{node2poly}}
}

\examples{
  ## TODO
  # PROBLEM: result file needed
  \dontrun{
 #geometry 
  geof <- read.geofile(file.path(.libPaths(), "Catflow", "Catflow-TEST", "in", "test.geo") )
 #relative saturation 
  res <- read.catf.resultmat(file.path(.libPaths(), "Catflow", "Catflow-TEST", "out", "relsat.out") )   
 
 # plot on screen  
  plot.catf.movie(res, geof,  sel =12:22,  
  colorsForCuts = c("pink",brewer.pal(8,"Blues")))   
  
 # plot to file  
  plot.catf.movie(res, geof, 
  SCREENPLOT = F, filename = "test.pdf",
  outputPath = ".",                                # current dir
  colorsForCuts = c("pink",brewer.pal(8,"Blues")))   
  
 # open pdf
 shell.exec( paste(getwd(), "Catflowtest.pdf", sep="/") )
 
 ## delete the produced file
  file.remove("Catflowtest.pdf")
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ utilities}

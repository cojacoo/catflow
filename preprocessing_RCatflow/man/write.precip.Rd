\name{write.precip}
\alias{write.precip}

\title{
Write a precipitation record for CATFLOW
}
\description{
Writes a file specifying the precipitation input for a CATFLOW simulation.
}
\usage{
write.precip(raindat, 
             output.file, 
             start.time = "01.01.2004 00:00:00", 
             time.unit = "h", faktor.p)
}

\arguments{
  \item{raindat}{
Rainfall data: either a \code{zoo} object with a POSIX index which holds the precipitation record;
or a data frame with two columns: time since start date, and precipitation
}
  \item{output.file}{
Name of file to produce
}
  \item{start.time}{
Start date for the simulation ("\%d.\%m.\%Y \%H:\%M:\%S")
}
  \item{time.unit}{
Time units of the precipitation record 
}
  \item{faktor.p}{
Conversion factor for rain rate to m/s (only needed if rate is NOT given as mm per 'time.unit')
}
}
\details{
The function 'write.precip' is used for its side-effect: writing a precipitation input file in CATFLOW-specific format.  
}
\value{
No value is returned. A short message indicates that a file has been produced.
}
\references{
Maurer, T. and E. Zehe (2007) \emph{CATFLOW User Guide and Program Documentation (Version Catstat)}
}
\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}

\seealso{
\code{\link{read.precip}}
}
\examples{
 \dontrun{
 # some rainfall record
  raindat <- data.frame("hours" = seq(0,48, by=0.5),
                        "precip" = c(rep(0,30), 1, rep(3,4), rep(2,3), 
                                      rep(0,25), rep(1,4), rep(0,30)) ) 
                      
 write.precip(raindat, "TEST.rain.dat", start.time= "01.01.2004 00:00:00" )
 
 file.show("TEST.rain.dat")
 
 ## maybe you like to delete the produced file
 unlink("TEST.rain.dat")
 }       
}

\keyword{ utilities}

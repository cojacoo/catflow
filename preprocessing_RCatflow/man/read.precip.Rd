\name{read.precip}
\alias{read.precip}

\title{
Read a CATFLOW precipitation record
}
\description{
Reads a precipitation record in CATFLOW-specific format, and returns a data frame or a
\code{zoo} object with the record. Optionally, the precipitation record is plotted.
}
\usage{
read.precip(file.nam = "./in/Klima/P_DB_knick_04.dat", 
            GMT.off = -3600, timzon = "GMT", plotting = TRUE)
}

\arguments{
  \item{file.nam}{
Name (and path) of the precipitation file
}
  \item{GMT.off}{
Offset to convert time zone of precipitation record to reference time zone
(e.g., CET -> GMT: -3600)
}
  \item{timzon}{
Reference time zone (e.g., GMT)
}
  \item{plotting}{
Logical indicating if plotting should be done
}
}
\details{
If the \code{zoo} package is installed, a \code{zoo} object with an index in POSIX format
is returned. To avoid possible problems with missing daylight saving time in the precipitation
record, the index vector is converted to a reference time zone without daylight saving, e.g.,
'GMT' (=UTC), and shifted by an appropriate offset. 

For example, if the time specification in
the record originally is Central European Time (strictly without daylight saving time), the
time is offset by -3600 s and treated as UTC. 

Otherwise, a data frame with time and precipitation is returned.  
}
\value{
Either a \code{zoo} object with the precipitation in original units and an index in POSIX
format (see details), or a data frame with time (time elapsed since the start date) and
precipitation in original units.
}
\references{
Maurer, T. and E. Zehe (2007) \emph{CATFLOW User Guide and Program Documentation (Version Catstat)}
}
\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}


\seealso{
 \code{\link{write.precip}}
}
\examples{
 \dontrun{
 # some rainfall data
  raindat <- data.frame("hours" = seq(0,48, by=0.5),
                        "precip" = c(rep(0,30), 1, rep(3,4), rep(2,3), 
                                      rep(0,25), rep(1,4), rep(0,30)) ) 
                      
 # write a CATFLOW rainfall file
 write.precip(raindat, "TEST.rain.dat", start.time= "01.01.2004 00:00:00" )
  file.show("TEST.rain.dat")
 
 # ... and read it again
 rain <- read.precip(file.nam = "TEST.rain.dat", plotting=T)
 
 ## maybe you like to delete the produced file
 #  unlink("TEST.rain.dat")
 }
}

\keyword{ utilities }


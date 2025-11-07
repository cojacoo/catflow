\name{read.climate}
\alias{read.climate}

\title{
Read a CATFLOW climate record
}
\description{
Reads a climate record in CATFLOW-specific format, and returns a data frame or a \code{zoo}
object with the record. Optionally, the climate record is plotted.
}
\usage{
read.climate( file.nam = "./in/Klima/climate_04.dat", 
              GMT.off = -3600, timzon = "GMT", plotting = TRUE, ...)
}

\arguments{
  \item{file.nam}{
Name (and path) of the climate file
}
  \item{GMT.off}{
Offset to convert time zone of climate record to reference time zone (e.g., CET -> GMT: -3600)
}
  \item{timzon}{
Reference time zone (e.g., GMT)
}
  \item{plotting}{
Logical indicating if plotting should be done
}
  \item{\dots}{
Arguments to be passed to plot methods, such as graphical parameters (see \code{par})
}
}
\details{
If the \code{zoo} package is installed, a \code{zoo} object with an index in POSIX format
is returned. To avoid possible problems with missing daylight saving time in the climate
record, the index vector is converted to a reference time zone without daylight saving, e.g.,
'GMT' (=UTC), and shifted by an appropriate offset. 

For example, if the time specification
in the record originally is Central European Time (strictly without daylight saving time),
the time is offset by -3600 s and treated as UTC.


Otherwise, a data frame with time and climate data is returned. 

}
\value{
Either a \code{zoo} object with the climate record and an index in POSIX format (see details),
 or a data frame with time (time elapsed since the start date) and climate record 
 in original units.
The climate record holds:
 \tabular{ll}{
\code{GlobRad}: \tab Global radiation [W/m²] \cr                                   
  \code{NetRad}: \tab Net radiation [W/m²]  \cr  
  \code{Temp}: \tab Temperature [°C] \cr  
  \code{RelHum}: \tab Relative humidity [\%] \cr  
  \code{vWind}: \tab Wind velocity [m/s] \cr  
  \code{dirWind}: \tab Wind direction [°, clockwise from North]\cr
}
}
\references{
Maurer, T. and E. Zehe (2007) \emph{CATFLOW User Guide and Program Documentation (Version Catstat)}
}
\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}

\seealso{
\code{\link{write.climate}}
}
\examples{
 \dontrun{
 # some climate record
  climadat <- data.frame(
              "hours" = seq(0,48, by=0.5),
              "GlobRad" =  ifelse(0 + 800 * sin((seq(0,48, by=0.5) - 8)*pi/12) > 0,
                                  0 + 800 * sin((seq(0,48, by=0.5) - 8)*pi/12),  0),
              "NetRad" = NA ,
              "Temp" = 4 +  sin((seq(0,48, by=0.5) - 12)*pi/12)  ,
              "RelHum" = 70 + 10* sin((seq(0,48, by=0.5))*pi/12) ,
              "vWind"  =  rlnorm(97, 0,1) ,
              "dirWind" = runif(97, 0, 359) 
              )
                      
 # write a climate file for CATFLOW
 write.climate(climadat, "TEST.clima.dat", start.time= "01.01.2004 00:00:00" )
                
 # ... and read it again
 clima <- read.climate("TEST.clima.dat")

 ## maybe you like to delete the produced file
   unlink("TEST.clima.dat")
 } 
}

\keyword{ utilities }

\name{write.climate}
\alias{write.climate}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Write a climate record for CATFLOW
}
\description{
Writes a file specifying the climate data input for a CATFLOW simulation.
}
\usage{
write.climate(climadat, 
              output.file, 
              start.time = "01.01.2004 00:00:00", 
              time.unit = "h", 
              rBilart = 1, 
              ref.height = 8, sw0 = -6, sw1 = 0.7, sw2 = 2.8e-4, 
              trueb = 1.5, truebf = 0.1,
              NA.flag = -999)
}

\arguments{
  \item{climadat}{
Climate data: either a \code{zoo} object with a POSIX index which holds the climate record;
or a data frame with time since start date in the first column, and a climate record in
subsequent columns.
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
  \item{output.file}{
Name of file to produce
}
  \item{start.time}{
Start date for the simulation ("\%d.\%m.\%Y \%H:\%M:\%S")
}
  \item{time.unit}{
Time units of the climate record 
}
  \item{rBilart}{
Climate file type: specifies whether net radiation is computed (1),
or measured values are to be used (2)
}
  \item{ref.height}{
Reference height of wind speed measurement
}
  \item{sw0, sw1, sw2}{
Factors relating short wave radiation balance and net radiation, to be calibrated
}

  \item{trueb, truebf}{
Factors for atmospheric dimming under consideration of water vapour pressure,
to be calibrated against clear sky radiation data
}
  \item{NA.flag}{
Flag for NA in the input data
}
}
\details{
The function 'write.climate' is used for its side-effect: writing a climate data
input file in CATFLOW-specific format.
}
\value{
No value is returned. A short message indicates that a file has been produced.
}
\references{
Maurer, T. and E. Zehe (2007) \emph{CATFLOW User Guide and Program Documentation (Version Catstat)}
}
\author{
Jan Wienhöfer
}

\seealso{
\code{\link{read.climate}}
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
                                                
 write.climate(climadat, "TEST.clima.dat", start.time= "01.01.2004 00:00:00" )
                
 file.show("TEST.clima.dat")
                
 ## maybe you like to delete the produced file
 unlink("TEST.clima.dat")
 }       
}

\keyword{utilities}


\name{write.printout}
\alias{write.printout}

\title{
Write printout times file for CATFLOW 
}
\description{
Writes a file with printout times for a CATFLOW simulation.
}
\usage{
write.printout( output.file = "printout.prt", 
                start.time = "01.01.2004 00:00:00", 
                end.time, length.prt, intervall, time.unit = "h",  
                flag = 1, first.time = 0)
}

\arguments{
  \item{output.file}{
Name of output file to produce
}
  \item{start.time}{
Start date for the simulation ("\%d.\%m.\%Y \%H:\%M:\%S")
}
  \item{end.time}{
End date for the simulation ("\%d.\%m.\%Y \%H:\%M:\%S")
}
  \item{length.prt}{
Length of printout record
}
  \item{intervall}{
Time interval between printout times
}
  \item{time.unit}{
Time units of printout times
}
  \item{flag}{
Flag controlling the amount of output at printout times, eventually a vector 
(1: dump all; 0: dump for surface nodes) 
}
  \item{first.time}{
First printout time
}
}
\details{
The function 'write.printout' is used for its side-effect: writing a file with printout time in CATFLOW-specific format. 
Of the three arguments 'end.time', 'intervall', or 'length.prt', two have to be specified to
construct the time column, which is time elapsed since the start date in the chosen units. If
all three are given, only 'intervall' and 'length.prt' are used. In this case, the last value
of the elapsed time not necessarily corresponds with the given 'end.time'.
}
\value{
No value is returned. A short message indicates which file has been produced.
}
\references{
Maurer, T. and E. Zehe (2007) \emph{CATFLOW User Guide and Program Documentation (Version Catstat)}
}
\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}


\examples{
  \dontrun{
  write.printout(output.file = "./in/printout.prt", 
                 start.time = "01.01.2004 00:00:00", 
                 end.time = "03.01.2004 00:00:00", 
                 intervall = 0.5, time.unit = "h",
                 flag = 1)
                  
  file.show( "printout.prt" )

  ## maybe you like to delete the produced file and directory  
  file.remove("printout.prt")
  }
}

\keyword{ utilities }


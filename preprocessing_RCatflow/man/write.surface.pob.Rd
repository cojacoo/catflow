\name{write.surface.pob}
\alias{write.surface.pob}

\title{
Write surface attribute file for CATFLOW
}
\description{
Writes a file specifying the attributes of the surface nodes for a CATFLOW simulation.
}
\usage{
write.surface.pob(output.file = "surface.pob", 
                  xs = xsi, lu = 33, climid = 1, precid = 1, 
                  windid = rep(1, 4), headr)
}

\arguments{
  \item{output.file}{
Name of file to produce
}
  \item{xs}{
Lateral discretization of slope profile (vector)
}
  \item{lu}{
Land-use ID:  either a single number to be assigned to all surface nodes, 
              or a vector of numbers of same length as xsi
}
  \item{climid}{
Climate ID:  either a single number to be assigned to all surface nodes, 
             or a vector of numbers of same length as xsi
}
  \item{precid}{
Precipitation ID: either a single number to be assigned to all surface nodes, 
                  or a vector of numbers of same length as xsi

}
  \item{windid}{
Wind direction ID:  either a vector of numbers representing different wind direction 
                    sectors which are to be assigned to all surface nodes, 
                    or a matrix of numbers with the same number of rows as xsi 
                    and as many columns as there are wind direction sectors (default: 4 sectors)
}
  \item{headr}{
Header line:  defaults to: \code{ paste("3  ", length(windid), "  0\n", 
                    "# Schlag-Id Clima-Id Niederschlag-Id Windrichtungsfaktoren",sep="")}
}
}
\details{
The function 'write.surface.pob' is used for its side-effect: writing a surface attribute file
in CATFLOW-specific format. 
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

\examples{
 \dontrun{
  write.surface.pob(output.file="surface.pob", 
                     xs=seq(0,1,length=11), 
                      lu=33,
                       windid= rbind(matrix(rep(c(2,3,4,5), 5), nrow=5, byrow=T),
                                     matrix(rep(c(1,2,3,4),6), nrow=6, byrow=T))
                      )
  
  file.show("surface.pob")
  
  ## maybe you like to delete the produced file
   file.remove("surface.pob")
  }
}

\keyword{utilities }


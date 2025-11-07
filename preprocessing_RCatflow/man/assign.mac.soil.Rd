\name{assign.mac.soil}
\alias{assign.mac.soil}

\title{
Write a file with node-wise assignment of soil identifiers
}
\description{
Writes a file for a node-wise assignment of soil identifiers for a CATFLOW simulation. 
If a matrix of values is given, e.g., a grid from some macropore simulation, a different soil
identifier is assigned to all nodes above a threshold. 
}
\usage{
assign.mac.soil(output.file = "soil_horizons.bod", 
                macgrid, eta = NULL, xsi = NULL,
                thresh = 1, soil.matrix = 1, soil.macro = 2, 
                numh = 1)
}

\arguments{
  \item{output.file}{
Name of file to produce
}
  \item{macgrid}{
A matrix of values resembling some macropore structures that are to be assgined an
alternative ID, with dimensions \code{dim(macgrid) = c(length(eta), length(xsi))}
}
  \item{eta}{
Vertical discretization of slope profile (vector). Required if \code{macgrid} is missing.
}
  \item{xsi}{
Lateral discretization of slope profile (vector). Required if \code{macgrid}' is missing.
}
  \item{thresh}{
Threshold for the values in macgrid above which the alternative soil ID is assigned.
}
  \item{soil.matrix}{
Default soil ID, e.g. for soil matrix
}
  \item{soil.macro}{
Alternative soil ID, e.g. for macroporous nodes
}
  \item{numh}{
Hillslope ID
}
}

\value{
No value is returned. A short message indicates that a file has been produced.
}


\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}


\seealso{
\code{\link{sim.mak}}, \code{\link{sim.rectmak}}, \code{\link{sim.pipe}}
}
\examples{
  \dontrun{
  set.seed(-80)
  
  assign.mac.soil(output.file = "soil_horizons.bod", 
                  macgrid= matrix(rnorm(30, mean=3, sd=1), nrow=5, ncol=6),
                  thresh = 4, soil.matrix = 1, soil.macro = 2, numh = 1)
  
  file.show("soil_horizons.bod")
  
  ## maybe you like to delete the produced file
     unlink("soil_horizons.bod")
  }
}

\keyword{utilities }

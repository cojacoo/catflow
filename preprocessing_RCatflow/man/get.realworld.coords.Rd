\name{get.realworld.coords}
\alias{get.realworld.coords}

\title{
Compute real-world coordinates of computational nodes.
}
\description{
Compute real-world coordinates (eastings and northings) for the nodes in a CATFLOW
simulation grid, which is read from a geometry file.
}
\usage{
get.realworld.coords(geofile, tol = 1e-3)
}

\arguments{
  \item{geofile}{
Name of the CATFLOW geofile
}
  \item{tol}{
Tolerance for agreement of local coordinates and (transformed) real-world coordinates [m].
}
}
\details{
An error occurs if the calculated real-world coordinates, transformed back to local
coordinates, do not match the original local coordinates within the specified tolerance
(default: 1e-3 m).
}
\value{A list of the real-world coordinates of the computational grid with two components:
 \item{Re}{matrix of real-world x-coordinates (easting)}
  \item{Ho}{matrix of real-world y-coordinate (northing)}
}

\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}

\seealso{
\code{\link{make.geometry}}, \code{\link{read.geofile}}
}
\examples{
 \dontrun{
  # example slope
  simple.slope <- list(
                      xh = seq(1,11, length=20),
                      yh = seq(2,8, length=20),
                      zh = approx(c(8,5),n=20)$y + sin((0:19)/2)/5 ,
                      bh = rep(1,20),
                      tot.area = 12 ,
                      htyp = 1, 
                      dyy = 2,
                      xsi = seq(0,1,length=11),
                      eta = seq(0,1,length= 6),
                      out.file="test.geo"    
                      # other parameters may take default values here
                      )

   # generate CATFLOW geometry and write file 'test.geo'
   test.slope <- make.geometry(simple.slope, make.output=T, plotting=F)
  
   # read the produced file and plot profile line (map view)
   test.rw.coords <- get.realworld.coords("test.geo")   
    matplot(test.rw.coords$Re, test.rw.coords$Ho, xlab="easting", 
            ylab="northing", main="Profile line ('simple slope')")

   # finally, you may like to delete the produced file and objects
    unlink("test.geo"); rm(simple.slope, test.slope, test.rw.coords)
 }
}

\keyword{ utilities }


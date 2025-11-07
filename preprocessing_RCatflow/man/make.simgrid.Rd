\name{make.simgrid}
\alias{make.simgrid}

\title{
Make a fine grid for macropore simulation
}
\description{
Interpolate a Cartesian simulation grid in fine resolution for the generation of a slope
profile with macroporous structures for the hydrological model CATFLOW.
}
\usage{
make.simgrid( slope,                              
              # data frame with coordinates, or four individual objects
              slope.xp, slope.yp, slope.zp, slope.width,    
              prof.depth, dx.max = 0.01, dz.max = 0.01)              
}

\arguments{
  \item{slope}{
Local coordinates of 2-D slope profile: dataframe with four columns (xp, yp, zp, width)
}
  \item{slope.xp}{
Horizontal x - coordinates (northing) of slope line [m]
}
  \item{slope.yp}{
Horizontal y - coordinates (easting) of slope line [m]
}
  \item{slope.zp}{
Vertical coordinates of slope line [m]
}
  \item{slope.width}{
Width of profile: uniform value, or a vector of same length as xp
}
  \item{prof.depth}{
Desired depth of profile
}
  \item{dx.max}{
Desired maximum horizontal resolution [m]
}
  \item{dz.max}{
Desired maximum vertical resolution [m]
}
}
\details{
The function \code{make.simgrid} is used to generate a macropore simulation grid for
a given slope line and a given depth. The coordinates of the slope profile and the width
along the slope line can be either given as a single data frame with four columns
(xp,yp,zp,width), or as individual arguments.
}
\value{
A list with the following components:
 \item{xnew}{Vector of local horizontal coordinates of simulation grid in fine resolution [m] (x-coordinates of columns as distance along slope line)}
 \item{znew}{Matrix of local vertical coordinates of simulation grid in fine resolution [m]}
 \item{width}{Vector of interpolated slope width in fine resolution [m]}
 \item{east}{Eastings of slope line in fine resolution [m]}
 \item{north}{Northings of slope line in fine resolution [m]}
}

\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}

\seealso{
\code{\link{sim.mak}}
}
\examples{
 # some slope line
 test.slope <- data.frame( xh = seq(1,11, length=20),
                           yh = seq(2,8, length=20),
                           zh = approx(c(8,5),n=20)$y + sin((0:19)/2)/5 ,
                           bh = rep(1,20) )
                          
 # simulation grid with 2 m depth and 0.1 m resolution
 test.sim.grid <- make.simgrid(test.slope, prof.depth = 2, dx.max=0.1, dz.max = 0.1)
 
}
\keyword{ utilities }


\name{sim.rectmak}
\alias{sim.rectmak}

\title{
Simulate a grid of macropores
}
\description{
Simulates a connected network of vertical and horizontal macropores on a simulation grid.
}
\usage{
sim.rectmak(xnew, znew, slope.width, 
            np = 4, ml = 0.9, sigl = 0.1, sigh = 0.1, x.step = 20, 
            kmacro, ksmean, relfak)
}

\arguments{
  \item{xnew}{
Vector of local horizontal coordinates of simulation grid [m] (x-coordinates of columns)
}
  \item{znew}{
Matrix of local vertical coordinates of simulation grid [m] (z-coordinates)
}
  \item{slope.width}{
Vector of slope width [m]
}
  \item{np}{
Number of macropores per unit area
}
  \item{ml}{
Mean vertical length of macropore [m]
}
  \item{sigl}{
Standard deviation of macropore length [m]
}
  \item{sigh}{
Standard deviation of depth of horizontal crossing (mean = half length)
}
  \item{x.step}{
Minimum seperation of individual macropores (in terms of columns of simulation grid)
}
  \item{kmacro}{
Optional: mean hydraulic capacity of macropores [m^3/s]
}
  \item{ksmean}{
Optional: mean hydraulic conductivity of soil matrix [m/s] 
}
  \item{relfak}{
Optional: multiplier grid, e.g., from earlier simulations
}
}
\details{
The function \code{sim.rectmak} is used to simulate a connected network of 
horizontal and vertical (non-tortuous) macropores. 
The geometry of the slope profile is given as a vector of horizontal and a matrix of 
vertical coordinates of the simulation grid.

A number of vertical macropores is determined for each grid column from a Poisson
distribution, while a minimum horizontal separation between macropores is kept. 
The individual lengths of the vertical macropores are drawn from a normal distribution.
These vertical macropores are then connected by horizontal macropores located at approximately
half the depth of the left vertical macropore.

Macropores within the simulation grid are identified by a factor > 1.  
With \code{kmacro} and \code{ksmean} given, this is a variable factor which relates the
hydraulic capacity of the simulated number of macropores per surface area to the average
hydraulic conductivity of the soil matrix. Otherwise, a constant factor of 2 is used.

The simulation can be combined with results from earlier simulations by given the result matrix
\code{relfak} as input argument.
}
\value{
A list with the components:
 \item{relfak}{Matrix with multipliers for simulation grid}
 \item{lmac}{Matrix with two rows of length = ncol(relfak): 
                \enumerate{
                \item{macropore lengths for each column}
                \item{deepest row number for each column}
                } 
             }
 \item{rowmac}{Vector with row numbers of horizontal structures at each column
               (0 if no horizontal structure in this column)}             
}

\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}

\seealso{
\code{\link{make.simgrid}}, \code{\link{plot.macros}}, 
\code{\link{sim.rectmak}}, \code{\link{sim.pipe}} 
}
\examples{
 # some slope line
 test.slope <- data.frame(xp = seq(0, by=0.614, length=20) ,
                          yp = seq(0, by=0.1, length=20) ,
                          zp = approx(c(8,5),n=20)$y + sin((0:19)/2)/5 ,
                          width = rep(1,20) )
                          
 # new simulation grid with 2 m depth and 0.1 m resolution
 test.sim.grid <- make.simgrid(test.slope, prof.depth = 2, dx.max=0.1, dz.max = 0.1)
 
 # simulate connected macropores
 sim <- sim.rectmak(test.sim.grid$x, test.sim.grid$z, test.sim.grid$width, x.step=10)
 
 \dontrun{
 # plot slope profile with simulated structures
 plot.macros(test.sim.grid$x, test.sim.grid$z, sim$relfak)
 }
}

\keyword{utilities}

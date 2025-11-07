\name{sim.pipe}
\alias{sim.pipe}

\title{
Simulate horizontal macropores
}
\description{
Simulates a horizontal macropore (pipe) on a simulation grid.
}
\usage{
sim.pipe( xnew, znew, slope.width, 
          start.depth, ml = 5, sigl, p.up = 0.1, p.down = 0.1, x.step = 20, 
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
  \item{start.depth}{
Starting depth of pipe [m]
}
  \item{ml}{
Mean horizontal length of macropore [m]
}
  \item{sigl}{
Standard deviation of macropore length [m] - defaults to 1/10 of \code{ml}
}
  \item{p.up}{
Probability for a step up
}
  \item{p.down}{
Probability for a step down
}
  \item{x.step}{
Step to the lateral after making a step up or a step down
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
The function \code{sim.pipe} is used to simulate a horizontal macropore (pipe). 
The geometry of the slope profile is given as a vector of horizontal and a matrix of 
vertical coordinates of the simulation grid.

The pipe starts at the right-hand side of the slope profile at the given starting depth.
The extent of the pipe (horizontal distance from the right) is drawn from a normal distribution (\code{ml}, \code{sigl}). The pipe is allowed to propagate
to higher or lower rows with \code{p.up} and \code{p.down}; 
a horizontal step of \code{x.step} is made after each vertical step.

Macropores within the simulation grid are identified by a factor > 1.  
With \code{kmacro} and \code{ksmean} given, this is a variable factor which relates the
hydraulic capacity of the simulated pipe to the average
hydraulic conductivity of the soil matrix. Otherwise, a constant factor of 2 is used.

The simulation can be combined with results from earlier simulations by given the result matrix
\code{relfak} as input argument.
}
\value{
A list with the components:
 \item{relfak}{Matrix with multipliers for simulation grid}
 \item{rowmac}{Vector with row numbers of horizontal structures at each column
               (0 if no horizontal structure in this column)}
 \item{lpip}{Extent of pipe (horizontal distance from the right)}                           
}

\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}

\seealso{
\code{\link{make.simgrid}}, \code{\link{plot.macros}},\code{\link{sim.mak}} 
\code{\link{sim.rectmak}}, \code{\link{discretize.pipe}} 
}
\examples{
 # some slope line
 test.slope <- data.frame(xp = seq(0, by=0.614, length=20) ,
                          yp = seq(0, by=0.1, length=20) ,
                          zp = approx(c(8,5),n=20)$y + sin((0:19)/2)/5 ,
                          width = rep(1,20) )
                          
 # new simulation grid with 2 m depth and 0.1 m resolution
 test.sim.grid <- make.simgrid(test.slope, prof.depth = 2, dx.max=0.1, dz.max = 0.1)
 
 # simulate pipe
 sim <- sim.pipe(test.sim.grid$x, test.sim.grid$z, test.sim.grid$width, 
                 start.depth = 1)
 
 \dontrun{
 # plot slope profile with simulated structure
 plot.macros(test.sim.grid$x, test.sim.grid$z, sim$relfak , pc = 1  )  
 }
}

\keyword{utilities}

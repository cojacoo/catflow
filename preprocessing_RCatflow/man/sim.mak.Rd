\name{sim.mak}
\alias{sim.mak}

\title{
Simulate vertical macropores
}
\description{
Random walk simulation of vertical macropores on a simulation grid. Up to two layers with
different random walk parameters can be simulated.
}
\usage{
sim.mak(xnew, znew, slope.width, 
        np = 4, ml = 0.9, sigl = 0.1, p.lat = 0.2, side = "both", x.step = 20, 
        depth, kmacro, ksmean, relfak)
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
  \item{p.lat}{
Probability for a lateral step (for two layers: vector with 2 elements)
}
  \item{side}{
Switch for making lateral steps only to the left or to the right ("left" or "right"), or in both directions ("both"). Currently, the same value is used for all layers.
}
  \item{x.step}{
Minimum seperation of individual macropores (in terms of columns of simulation grid)
}
  \item{depth}{
Optional: depth of layer boundary in case of two different layers
}
  \item{kmacro}{
Optional: mean hydraulic capacity of macropores [m^3/s]
}
  \item{ksmean}{
Optional: mean hydraulic conductivity of soil matrix [m/s] (for two layers: vector with 2 elements)
}
  \item{relfak}{
Optional: multiplier grid, e.g., from earlier simulations
}

}
\details{
The function \code{sim.mak} is used to simulate tortuous vertical macropores.
The geometry of the slope profile is given as a vector of horizontal and a matrix of 
vertical coordinates of the simulation grid.

The number of macropores at the surface is determined for each grid cell from a Poisson
distribution, while a minimum separation between macropores is kept. 
The propagation of macropores from the surface is simulated as a Random Walk; 
the individual lengths of the macropores are drawn from a normal distribution.

Macropores within the simulation grid are identified by a factor > 1.  
With \code{kmacro} and \code{ksmean} given, this is a variable factor which relates the
hydraulic capacity of the simulated number of macropores per surface area to the average
hydraulic conductivity of the soil matrix. Otherwise, a constant factor of 2 is used.

Two different soil layers can be considered, with different probabilities \code{p.lat}
and different soil matrix conductivities \code{ksmean}, by giving the \code{depth}
for the layer boundary.

The simulation can be combined with results from earlier simulations by given the result matrix
\code{relfak} as input argument.
}
\value{
A list with the components:
 \item{relfak}{Matrix with multipliers for simulation grid}
\item{lmac}{Matrix with two rows of length = ncol(relfak):\
                macropore lengths for each column
                deepest row number for each column
            }
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
 
 # simulate vertical macropores
 sim <- sim.mak(test.sim.grid$x, test.sim.grid$z, test.sim.grid$width, x.step=10)
 \dontrun{
 # plot slope profile with simulated structures
 plot.macros(test.sim.grid$x, test.sim.grid$z, sim$relfak)
 }
}

\keyword{ utilities }


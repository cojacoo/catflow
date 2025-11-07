\name{discretize.rect}
\alias{discretize.rect}

\title{
Make new discretization for connected macropores
}
\description{
Computes a new discretization (xsi- and eta vectors) keeping the fine grid resolution around 
connected macropores simulated with \code{\link{sim.rectmak}}.
}
\usage{
discretize.rect(sim, steph = 1, stepv = 1, maxdists, dimfaks, 
                top = 1:3, reg = TRUE, plottin = TRUE)
}

\arguments{
  \item{sim}{
List with multiplier matrix, vector of length/deepest position of vertical structures
and vector with positions of horizontal structures, 
from macropore simulations with \code{sim.rectmak} 
}
  \item{steph}{
Steps for keeping horizontal resolution around macroporous structures [no. of columns]
}
  \item{stepv}{
Steps for keeping vertical resolution around horizontal macropores and at endings of vertical
[no. of rows]
}
  \item{maxdists}{
Maximum lateral and/or vertical seperation of simulation nodes [no. of columns/rows]
(either a vector for the lateral and vertical, or a single value for both; 
if missing, \code{dimfaks} is used)        
}
  \item{dimfaks}{
Fraction of dimensions to compute missing \code{maxdists}
(either a vector for the lateral and vertical, or a single value for both;
 default: \code{c(0.025,0.05)}, i.e. 2.5\% in lateral and 5.0\% in vertical direction)
}
  \item{top}{
Vector of nodes at upper boundary which should keep a finer discretization
}
  \item{reg}{
Flag for generating a regular grid using \code{maxdists}
}
  \item{plottin}{
Logical if plotting should be done
}
}
\details{
The function \code{discretize.rect} is used to compute discretization vectors for a CATFLOW
model domain
based on connected macropores that were simulated on a fine grid with the 
function \code{sim.rectmak}.
It is a wrapper for the internal functions \code{discretize.xsi} and \code{discretize.eta}.

The lateral discretization (xsi-vector) is computed such that the fine resolution is kept at the
locations of vertical macropore +/-\code{steph}, while the remaining domain is discretized with 
maximum size of \code{maxdists[1]} columns when \code{reg = TRUE}
(\code{maxdists[1]} is calculated as \code{dimfaks[1]} * \code{ncol(sim)}, if missing) .  

The vertical discretization (eta-vector) is computed such that the fine resolution is kept at the
\code{top} rows and around the horizontal 
macropores +/-\code{stepv}, while the remaining domain is discretized with a 
maximum size of \code{maxdists[2]} rows when \code{reg = TRUE}
(\code{maxdists[2]} is calculated as \code{dimfaks[2]} * \code{nrow(sim)}, if missing). 

If desired (\code{plottin = TRUE}), the resulting discretization is plotted schematically.
}
\value{
A list with three components:
 \item{xsi}{Vector with lateral discretization of model domain}
 \item{eta}{Vector with vertical discretization of model domain}
 \item{macgrid}{Multiplier matrix/macropore positions, scaled to new grid}
}
\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}

\seealso{
\code{\link{sim.rectmak}}, \code{\link{discretize.mak}}, \code{\link{discretize.pipe}}
}
\examples{
 # some slope line
 test.slope <- data.frame(xp = seq(0, by=0.614, length=20) ,
                          yp = seq(0, by=0.1, length=20) ,
                          zp = approx(c(8,5),n=20)$y + sin((0:19)/2)/5 ,
                          width = rep(1,20) )
                          
 # new simulation grid with 2 m depth and 0.1 m resolution
 test.sim.grid <- make.simgrid(test.slope, prof.depth = 2, dx.max=0.05, dz.max = 0.05)
 
 # simulate vertical macropores
 sim <- sim.rectmak(test.sim.grid$x, test.sim.grid$z, test.sim.grid$width, x.step=10)
 
 # plot slope profile with simulated structures
 plot.macros(test.sim.grid$x, test.sim.grid$z, sim$relfak)
 
 # new xsi- and eta vectors
 disc <- discretize.rect(sim, maxdists = c(5,3), plottin = TRUE)

}

\keyword{utilities }
\name{plot.macros}
\alias{plot.macros}

\title{
Plot simulated macropores
}
\description{
Plots a slope profile with simulated macropores. 
}
\usage{
plot.macros(x, z, relfak, pc = 0.1, ...)
}

\arguments{
  \item{x}{
Vector of local horizontal coordinates of simulation grid [m] (x-coordinates of columns)
}
  \item{z}{
Matrix of local vertical coordinates of simulation grid [m] (z-coordinates)
}
  \item{relfak}{
Multiplier matrix from macropore simulations
}
  \item{pc}{
Point exaggeration factor for plotting the macroporous grid cells
}
  \item{\dots}{
Arguments to be passed to plot methods, such as graphical parameters (see \code{par}).  
}
}
\details{
The function \code{plot.macros} is mainly used for its side-effect: plot a slope 
profile with simulated macropores. 
}
\value{
No value.
}

\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}

\seealso{
\code{\link{sim.mak}}, \code{\link{sim.rectmak}}, \code{\link{sim.pipe}}
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

\keyword{utilities}

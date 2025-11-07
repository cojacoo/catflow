\name{mac.grid}
\alias{mac.grid}

\title{
Position of macropores for new discretization vectors
}
\description{
Scales the positions of macroporous nodes from multiplier matrix in fine resolution
into a grid corresponding to new eta- and xsi vectors. 
}
\usage{
mac.grid(relfak, xnew, znew, xsi_new, eta_new, plottin = FALSE)
}

\arguments{
  \item{relfak}{
Matrix with macropore multipliers, e.g. from \code{sim.mak}  
}
  \item{xnew}{
Vector of horizontal coordinates of macropore simulation grid [m] (x-coordinates of columns)
}
  \item{znew}{
Matrix of vertical coordinates of macropore simulation grid [m] (z-coordinates)
}
  \item{xsi_new}{
Vector with new lateral discretization of model domain, e.g. from \code{discretize.mak} 
}
  \item{eta_new}{
Vector with new vertical discretization of model domain, e.g. from \code{discretize.mak} 
}
  \item{plottin}{
Logical if plotting should be done
}
}
\details{
The function \code{mac.grid} may be useful if macropores have been simulated on a 
relatively fine grid, and new discretization vectors have been determined.
It determines the positions of macropores in the new simulation grid, based on the
simulated multiplier matrix and the new discretization vectors. 
}
\value{
A matrix of logicals indicating macroporous nodes in terms of the given
eta - xsi - discretization.
}


\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}
\note{
To avoid possible numerical artifacts in the determination of new grid indices, 
a small number (1e-7) is added to the eta - xsi - values.
The function \code{\link{discretize.rect}} also returns a matrix for connected macropores
simulated with \code{\link{sim.rectmak}}, but this contains the simulated scaling factors.

}



\seealso{
\code{\link{sim.mak}}, \code{\link{sim.pipe}},
\code{\link{discretize.mak}},  \code{\link{discretize.pipe}}
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
 
 # new xsi- and eta vectors
 disc <- discretize.mak(sim, maxdists = c(5,3), plottin = TRUE)

 # macropore matrix
 new.grid <-  mac.grid(relfak = sim[[1]], xnew = test.sim.grid$x, znew = test.sim.grid$z,
                       xsi_new = disc$xsi, eta_new = disc$eta, plottin = TRUE)
}

\keyword{utilities}

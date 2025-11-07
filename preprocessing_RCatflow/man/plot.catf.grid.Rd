\name{plot.catf.grid}
\alias{plot.catf.grid}

\title{
Plots a CATFLOW simulation grid
}
\description{
Plots a CATFLOW geometry as polygons around the simulation nodes, with optional
color coding of some values at each node.
}
\usage{
plot.catf.grid(x = sko, y = hko, 
                val = NULL, sel = NULL, 
                 pal, boundcol = 8, 
                  plotting = TRUE, plotlab = TRUE, plotpoints = FALSE, ...)
}

\arguments{
  \item{x}{
Matrix of local horizontal coordinates of simulation nodes [m]
}
  \item{y}{
Matrix of local vertical coordinates of simulation nodes [m]
}
  \item{val}{
Matrix of values at simulation nodes
}
  \item{sel}{
Range of columns for subsetting, if desired
}
  \item{pal}{
Color palette for color coding. Defaults to a 'jet color' palette.
}
  \item{boundcol}{
Color value for boundary lines of node polygons
}
  \item{plotting}{
Logical indicating if plotting should be done
}
  \item{plotlab}{
Logical indicating if a legend should be plotted
}
  \item{plotpoints}{
Logical indicating if nodes should be plotted as points
}
  \item{\dots}{
Arguments to be passed to plot methods, such as graphical parameters (see \code{par}).  
}
}
\details{
The function \code{plot.catf.grid} is mainly used for its side-effect: plot a CATFLOW 
geometry in a polygon representation, optionallly with color-coding of some values, 
e.g., simulation results. 
}
\value{
When assigned, a list with two components is returned:
\item{pcx }{x-coordinates of polygons}
\item{pcy }{y-coordinates of polygons}
}

\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}

\seealso{
\code{\link{make.geometry}}
}
\examples{
 \dontrun{
 # ... a simple slope
 simple.slope <- list(xh = seq(1,11, length=20),
                      yh = seq(2,8, length=20),
                      zh = approx(c(8,5),n=20)$y + sin((0:19)/2)/5 ,
                      bh = rep(1,20),
                      tot.area = 12 ,
                      htyp = 1, 
                      dyy = 2,
                      xsi = seq(0,1,length=11),
                      eta = seq(0,1,length= 6)
                      ) # other parameters may take default values here
                      
 # generate CATFLOW geometry                     
 test.geom <- make.geometry(simple.slope, make.output=FALSE, plotting=FALSE)            

 # plot CATFLOW geometry and color-code the nodes according to elevation
 plot.catf.grid(test.geom$sko, test.geom$hko, val=test.geom$hko, plotpoints=TRUE)
 }
}

\keyword{utilities }


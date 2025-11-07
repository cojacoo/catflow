\name{node2poly}
\alias{node2poly}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Generates polygons around simulation nodes
}
\description{
Internal function of the CATFLOW package to compute polygons around the simulation
nodes for plotting purposes.
}
\usage{
node2poly(xv = sko, yv = hko, sel)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{xv}{
Matrix of local lateral coordinates of simulation nodes
}
  \item{yv}{
Matrix of local vertical coordinates of simulation nodes
}
  \item{sel}{
Vector for selection of columns (optional)
}
}
\details{
The polygons are determined such that their boundaries are at the midpoints
between the (internal) nodes. The nodes at the boundaries are limited by the overall
boundaries.

The resulting polygons are returned as two vectors with horizontal and vertical
coordinates of the polygon vertices, where two polygons are seperated by \code{NA}.
}
\value{
A list with three components:
  \item{hor }{vector of horizontal coordinates of polygon vertices}
 \item{vert }{vector of vertical coordinates of polygon vertices}
 \item{area }{vector of polygon areas}
}

\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}
\seealso{
\code{\link{polygon}}
}

\keyword{internal}

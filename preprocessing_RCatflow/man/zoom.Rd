\name{zoom}
\alias{zoom}

\title{
Zooming for plots
}
\description{
Provides zoom functionality for high-level plots.
}
\usage{
zoom(fun, ...)
}

\arguments{
  \item{fun}{
  Function that generates some sort of plot. The \code{\dots} argument needs to be part of the
  function's argument list (see example).
}
  \item{\dots}{
    Arguments to be passed to plot methods, such as graphical parameters (see \code{par}).  
}
}

\details{
The function is evoked for its side effect: Zooming into an existing plot by mouse-clicking.
You may also zoom out by clicking outside the axis.
Double-clicking restores original extent.
}
\value{
No value is returned. Short messages indicate the extent of the zoom area.
}

\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}
\note{
This function was adapted from the \code{zoom} function provided with the \code{Hmisc} package.)
}

\examples{
  \dontrun{
  x <- 1:20
  y <- runif(20)
  
  plotfun <- function(...) plot(x,y, t="b",...)
  
  zoom(fun=plotfun, col=2)
  }
}

\keyword{iplot}


\name{color.codes}
\alias{color.codes}

\title{
Color coding for plotting CATFLOW results
}
\description{
Internal function of the CATFLOW package to determine color codes for given values.     
}
\usage{
color.codes(val, 
            lowercut = 0, uppercut = 1, lencut = 8, 
            colorsForCuts, 
            plotlab = TRUE)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{val}{
Matrix of values that are to be color-coded
}
  \item{lowercut}{
Value for the lower cut of the color code
}
  \item{uppercut}{
Value for the upper cut of the color code
}
  \item{lencut}{
Length of the color code palette
}
  \item{colorsForCuts}{
Color palette to be used (optional)
}
  \item{plotlab}{
Logical if a legend with the color code should be drawn
}
}
\details{
This (internal) function is used in \code{plot.catflow.movie}.

If no palette is given by \code{colorsForCuts}, a palette of pink and blues is aquired
using the \code{RColorBrewer} package. 
}
\value{
A vector of colors for each value in \code{val}.
}

\author{
Tobias Vetter, Jan \enc{Wienhöfer}{Wienhoefer}
}
\note{
An adaption of a code chunk found at \url{http://www.experimental-hydrology.net/models/}.
}

%% ~Make other sections like Warning with \section{Warning }{....} ~

\keyword{internal}
\name{fromArcGIS}
\alias{fromArcGIS}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Import slope geometry from ArcGIS CATFLOW wizard
}
\description{
Reads the slope geometry output file produced by the ArcGIS CATFLOW wizard and returns a list 
useful for generating the CATFLOW hillslope geometry with the function \code{make.geometry}.
}
\usage{
fromArcGIS(filename)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{filename}{
Name (and path) of the file to read
}
}
\details{
%%  ~~ If necessary, more details than the description above ~~
}
\value{
a list with the components:
 
    -  xh       : x-coordinate of slope line (northing) [m]
    
    -  yh       : y-coordinate of slope line (easting) [m]
    
    -  zh       : z-coordinate of slope line (surface elevation) [m]
    
    -  tot.area : total area of slope [m²]
    
    -  bh       : slope width [m]
    
    -  dyy      : thickness of profile [m]
    
    -  xsi      : relative discretization in lateral direction
    
    -  eta      : relative discretization in vertical direction
   
    -  htyp     : type of geometry: (1) constant thickness (default), (2) cake-shape 
   
    -  numh     : ID of slope 
      
    -  ho_bez   : point of reference for y-coordinate of slope profile (northing)
   
    -  re_bez   : point of reference for x-coordinate of slope profile (easting)
   
    -  z_bez    : point of reference for z-coordinate of slope profile (elevation)
   
    -  w.aniso  : angle of main direction of anisotropy,  positive counterclockwise
   
    -  out.file : name for CATFLOW geofile to produce (generated from slope ID)
}
\references{
Reusser, D. (2004) Documentation to the CATFLOW wizard. [catflow.chm]
}
\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}
\note{
%%  ~~further notes~~
}

%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{
 \code{\link{make.geometry}}
}
\examples{
### example File !!
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ utilities }


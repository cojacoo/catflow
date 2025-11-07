\name{read.geofile}
\alias{read.geofile}
\title{
Reads a CATFLOW geometry file
}
\description{
Reads a CATFLOW geometry from a text file, e.g. produced with 'make.geometry'.
}
\usage{
read.geofile(geofile)
}

\arguments{
  \item{geofile}{
Name of the CATFLOW geometry file
}
}


\value{A list with the following components:
 \item{hko}{matrix of local vertical coordinates of the computational grid}
 \item{sko}{matrix of local horizontal coordinates of the computational grid}
 \item{xsi}{lateral discretization of slope profile}
 \item{eta}{vertical discretization of slope profile}
 \item{slope.width}{slope width along lateral discretization}
 \item{realworld.coords}{real-world coordinates of surface nodes; a data frame with two columns:
                        \enumerate{
                          \item Re: real-world x coordinate (easting)
                          \item Ho: real-world y coordinate (northing)
                         }
                        }
}

\references{
Maurer, T. and E. Zehe (2007) \emph{CATFLOW User Guide and Program Documentation (Version Catstat)}
}
\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}



\seealso{
 \code{\link{make.geometry}}
}
\examples{
  \dontrun{
    # example slope
    simple.slope <- list(
                        xh = seq(1,11, length=20),
                        yh = seq(2,8, length=20),
                        zh = approx(c(8,5),n=20)$y + sin((0:19)/2)/5 ,
                        bh = rep(1,20),
                        tot.area = 12 ,
                        htyp = 1, 
                        dyy = 2,
                        xsi = seq(0,1,length=11),
                        eta = seq(0,1,length= 6),
                        out.file="test.geo"    
                          # other parameters may take default values here
                          )
  
    # generate CATFLOW geometry and write file 'test.geo'                   
    test.slope <- make.geometry(simple.slope, make.output=T, plotting=F)
    
    # read the produced file and plot computational nodes
    test.geom <- read.geofile("test.geo")
      with(test.geom, plot(sko, hko, t="p"))
   
    ## finally, delete the produced file and objects
    unlink("test.geo"); rm(simple.slope, test.slope, test.geom)
  }                
}

\keyword{ utilities }

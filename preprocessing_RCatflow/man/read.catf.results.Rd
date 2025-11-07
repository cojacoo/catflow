\name{read.catf.results}
\alias{read.catf.results}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Read all results of a CATFLOW simulation
}
\description{
Reads several result files from a CATFLOW simulation and returns them as a list.
}
\usage{
read.catf.results(resdir, 
                  result.files.mat = c("psi.out", "relsat.out", 
                                       "theta.out", "fl_xsi.out", 
                                       "fl_eta.out", "senken.out"),
                  balance.file, surfrun.file, evapo.file,
                  saving = TRUE, target.dir  ) 
}

\arguments{
  \item{resdir}{
Name of directory with result files
}
  \item{result.files.mat}{
Character vector with the names of the files to read with results in matrices
}
  \item{balance.file}{
Name of the balance file to read (optional)
}
  \item{surfrun.file}{
Name of the surface runoff file to read (optional)
}
  \item{evapo.file}{
Name of the evapo-transpiration file to read (optional)
}
  \item{saving}{
Logical: should the results be saved as \R object? 
}
  \item{target.dir}{
Target directory for the \R object to be saved (optional) 
}
}
\details{
If \code{saving == TRUE}, the CATFLOW results are saved as an \R object with the name
"(/resdir).obj" (the name of the last folder of \code{resdir})
in the specified target directory (if missing, the directory with the result files is used).
If the respective arguments are missing, the balance, surface runoff
and evapotranspiration files are not read.
}
\value{
A list with CATFLOW results read from the given files:
 \item{time}{simulation times for results in matrices}
 \item{\ldots}{results in matrices as given by \code{result.files.mat}}
 \item{balance}{water balance}
 \item{surf.runoff}{surface runoff}
 \item{evapo}{evapotranspiration}
 
A short message indicates which files were successfully read.
}

\seealso{
\code{\link{read.catf.resultmat}}, \code{\link{read.catf.balance}},
\code{\link{read.surfrun.out}}, \code{\link{read.evapo.out}},  
}

\examples{
## TO DO 
## PROBLEM: result files
}


\keyword{utilities}
\name{catf.batch.cleanup}
\alias{catf.batch.cleanup}

\title{
Batch cleanup after CATFLOW simulation
}
\description{
Copies some input files and files from the main simulation directory to a specified directory.
The input directory and the remaining input files then are deleted.
}
\usage{
catf.batch.cleanup(fol, 
                   indir = "./in", tardir = "./Preproc", 
                   interact = TRUE)
}

\arguments{
  \item{fol}{
Name of simulation directory to clean
}
  \item{indir}{
Name of the subdirectory containing the input files
}
  \item{tardir}{
Name of the new subdirectory for the files to keep
}
  \item{interact}{
Logical if function is used interactively 
}
}
\details{
These files are saved:

- from the simulation directory: 

 \code{*.dat}: 'dat' files produced by CATFLOW

 \code{*.obj}: 'obj' files, e.g., saved \R objects

- from the input subdirectory:

  \code{*.geo}: geometry file for CATFLOW simulation

  \code{*.bod}: soil identifier file for CATFLOW simulation
 

The rest of the input files in the simulation directory (i.e., directly contained in the
folder 'fol') is removed, also the 'CATFLOW.IN' or your simulation control file!

Further subdirectories of 'fol', like results directories, are not modified.

This function is particularly useful with batch simulations, where several CATFLOW runs
sharing a lot of the input files have been made.
}
\value{
When assigned, a short message indicating which folder has been cleaned.
}
\references{
Maurer, T. and E. Zehe (2007) \emph{CATFLOW User Guide and Program Documentation (Version Catstat)}
}
\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}


\section{Warning }{Use with care!} 

\seealso{
\code{\link{del.files}}
}
\examples{
 \dontrun{
  # some input files
    test.files <- c("del.me.dat", "del.me.in", "del.me.geo")
  # make dummy simulation directory
    dir.create("./TEST.CATFLOW")
  # produce dummy test files in simulation directory
    sapply( test.files, function (nam) {
            cat("Test file 1 for function 'catf.batch.cleanup' (package CATFLOW)", 
            file= paste("./TEST.CATFLOW", nam, sep="/1") )    
            return("written")})
  ## make dummy input subdirectory
    dir.create("./TEST.CATFLOW/test.in")  
  ## produce dummy test files in input subdirectory
    sapply( test.files, function (nam) {
            cat("Test file 2 for function 'catf.batch.cleanup' (package CATFLOW)", 
            file= paste("./TEST.CATFLOW/test.in", nam, sep="/2") )    
            return("written")})

  print(dir("TEST.CATFLOW", rec=T))

  # ... and delete the dummy files, keeping '1del.me.dat' and '2del.me.geo'
  catf.batch.cleanup("./TEST.CATFLOW", indir = "./test.in", interact = FALSE)

  print(dir("TEST.CATFLOW", rec=T))
   
## delete the produced dummy simulation directory with all contents
  unlink("./TEST.CATFLOW", rec=T)
 }
}

\keyword{ utilities }

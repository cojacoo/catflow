\name{del.files}
\alias{del.files}

\title{
Delete unnecessary simulation results
}
\description{
Deletes files in 'out'-subdirectories of specified simulation directory.
}
\usage{
del.files(direct, 
          subdir = "out", file2del=c("ve.out", "vx.out", "c.out") )
}

\arguments{
  \item{direct}{
Parent directory where to look for simulation results.
}
  \item{subdir}{
Substring of subdirectories that contain unnecessary files.
}
  \item{file2del}{
Name(s) of file(s) to delete
}
}
\details{
The function is used for its side-effect: removing unncessary files, e.g., empty 
concentration files from CATFLOW runs without simulation of solute transport.
The specified files are deleted in all subdirectories of the specified directory 
\code{direct} which name matches the \code{subdir} pattern. 
}
\value{
No value is returned. A short message indicates which files have been removed.
}

\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}


\section{Warning }{Use with care.} 

\seealso{
  \code{\link{catf.batch.cleanup}}
}
\examples{
  \dontrun{
    # make dummy simulation directory
      dir.create("./TEST.CATFLOW")
    # make dummy results subdirectory
      dir.create("./TEST.CATFLOW/test.out")  
    # some unnecessary concentration results
      test.files <- c("ve.out", "vx.out", "c.out")
    # produce dummy test files
      sapply( test.files, function (nam) {
              cat("Test file for function 'del.files' (package CATFLOW)", 
              file= paste("./TEST.CATFLOW/test.out", nam, sep="/") )    
              return("written")})
  
    print(dir("TEST.CATFLOW", rec=T))
    
    # ... and delete the dummy files
    del.files("./TEST.CATFLOW", file2del=test.files)
  
  ## delete the produced dummy simulation directory with all contents
     unlink("./TEST.CATFLOW", rec=T)
  }
}

\keyword{utilities }

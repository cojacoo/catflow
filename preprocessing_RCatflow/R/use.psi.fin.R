use.psi.fin <-
function(resultfile, inidir, ininame, make.newini=TRUE)
{

ininame <- sub(".ini", "",ininame)  # removing suffix

# initialise
simtim <- vector("numeric")
numh <-   vector("character")
ynum <- vector("numeric")
xnum <- vector("numeric")

val <- list()
i <- 1

file1 <- file(resultfile, "r")


repeat{
  header  <- readLines(file1, n = 1)
  header  <-unlist(strsplit(header, "[[:blank:]]{2,}"))

 if(length(header) == 6)
  {stopifnot(identical(header[1],"PSI"))
  simtim[i] <- header[2]
   numh[i] <- header[3]
   ynum[i] <- as.numeric(header[4])
   xnum[i] <- as.numeric(header[5])

  val[[i]] <-  as.matrix(read.table(file1, nrows =  ynum[i]))
           dimnames(val[[i]]) <- NULL

     i <- i +1
    } else { if (length(header) == 0) {
              #print("End of file")
              break()
              } else stop("Problems during read!")
            }

}                      # end read file

close(file1)

names(val)  <- numh

 if(make.newini){
  # write ini files
  if(length(val) == 1) {
      outfile <- file.path(inidir, paste(ininame,".ini", sep=""))
      write.facmat(outfile, et= 1:ynum, xs=1:xnum, headr = paste("PSI  0", numh, ynum, xnum, 1), fac=val[[1]])
  } else {
      for(i in 1:length(val)) {
      outfile <- file.path(inidir, paste(ininame, numh[i],".ini", sep=""))
      write.facmat(outfile, et= 1:ynum[i], xs=1:xnum[i], headr = paste("PSI  0", numh[i], ynum[i], xnum[i], 1), fac=val[[i]])
      }
    }  
  
 cat(paste("Generated files with initial conditions:", file.path(inidir, ininame), paste(1,"...", length(val)),"\n"))
 }

 return(invisible(val))
}


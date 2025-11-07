read.catf.resultmat <-
function( resultfile){

simtim <- vector("numeric")
numh <-   vector("character")
val <- list()
i <- 1

file1 <- file(resultfile, "r")

 # correct character representations  with high exponents (e.g. -0.605-123 --> 6.05e-124)
 char2num <- function(x, st1 = 1, en1 = 6, st2 = 7, en2 =  11){
                 a <-  substr( x, st1, en1)
                  b <-  substr(x, st2, en2)
                   c <- as.numeric(paste(a, "e", b, sep = ""))
              return(c)} 

 repeat{
  colu <- scan(file1, nlines = 1, quiet = TRUE)

   if (length(colu) == 4) {
     # four numbers: first is timestep
     simtim[i] <- colu[1]
     numh[i] <- colu[2]
     ynum <- colu[3]
     xnum <- colu[4]
     # next 'ynum' lines are values
      val[[i]] <- as.matrix(read.table(file1, nrows =  ynum))
           dimnames(val[[i]]) <- NULL
       
       if(mode(val[[i]]) ==  "character") {
           
            ow <-  options(warn = -1 )       # turn off warnings
            blub <- as.numeric(val[[i]]) 
            options(ow)                     # reset options
          
          # non-convertible entries
           if(any(is.na(blub))) warning(
                                paste("Ambiguous entries in",
                                resultfile, 
                                paste("\ntimestep", simtim[i],
                                "position", 
                                 apply(
                                      which(is.na(matrix(blub, ncol=xnum, nrow=ynum)), 
                                      arr.ind = TRUE), 1, paste, collapse=", ") 
                               , collapse="")) )
                                               
           blub[which(is.na(blub))] <- char2num(val[[i]][which(is.na(blub))] )
           val[[i]] <- matrix(blub, dim(val[[i]]) )
          
        }
      i <- i +1
    } else { if (length(colu) == 0) {
              #print("End of file")
              break()
              } else stop("Problems during read!")
            }
 }
close(file1)
 print(paste(resultfile, "read sucessfully."))

names(val) <- paste("ID", numh, sep = "")

 if(length(unique(names(val)))>1)
               { vallist <- vector("list",length(unique(names(val))) )
                 for( j in 1:length(unique(names(val))) ){
                  vallist[[j]] <- list("val" =val[grep(unique(names(val))[j], names(val))],"time"=simtim[grep(unique(names(val))[j], names(val))] )
                  }
                names(vallist) <-  unique(names(val))
                return(vallist)   
                 
 } else return(list("val" = val, "time" = simtim)) 

}

            # 
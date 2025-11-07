read.catf.results <-
function(resdir,
         result.files.mat = c("psi.out", "relsat.out", "theta.out", 
         "fl_xsi.out", "fl_eta.out", "senken.out"),
         balance.file , 
         surfrun.file ,
         evapo.file ,
         saving = TRUE, 
         target.dir ) 
{
 if(missing(target.dir))  target.dir <- resdir

# generate filenames to read from resdir argument
files2read <- as.list(file.path(resdir,  result.files.mat ))


# read all files and return list
res <- lapply(files2read, function(x) { erg <- read.catf.resultmat(x)
                                       gc()
                                       return(erg)}
                                        ) 
 names(res) <- result.files.mat
 
 
# extract time - first check if equal in all files
simtim <- sapply(res, function(x) x[["time"]])

  if(!class(simtim) %in% c("data.frame","matrix")){
     short.file <- result.files.mat[which.min(sapply(simtim, length))]
       stop(paste("Time steps not equal in out.files!",
                  "Check", short.file) ) 
   }

 if(ncol(simtim)>1)
  {
  ind <- combn(1:ncol(simtim),2, simplify = FALSE) 
  ind <- sapply(ind, function(x, y = simtim) all.equal(y[,x[1]], y[,x[2]]))
  
  stopifnot(all(ind))      # stops if not unique time vector in all files
  }
  
 # keep only values, not time in results list
 for(i in 1:length(res)) res[[i]] <- res[[i]][[1]]

 # add time vector
 res$time <- simtim[,1]
 
# balance file
if(!missing(balance.file)) {
    res$balance <- read.catf.balance( file.path(resdir,balance.file))  }

# surface runoff
if(!missing(surfrun.file)) {
    res$surf.runoff <- read.surfrun.out( file.path(resdir,surfrun.file)) }
    
if(!missing(evapo.file)) {
    res$evapo <- read.evapo.out( file.path(resdir,evapo.file)) }
   

 # save results
 if(saving) 
  { filnam <- file.path(target.dir, paste(rev(unlist(strsplit(resdir,"/")))[1],"obj",sep=".")  )
    save(res, file=filnam)  }
    
  gc()
  
return(res) 
}


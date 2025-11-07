write.facmat <-
function(output.file, et = eta, xs = xsi, headr, numh = 1, fac = 1) {
      
  
  if(missing(headr)) headr <- paste(-1000-numh, length(et), length(xs))
  
  if(missing(output.file)) OUT <- FALSE    else OUT <- TRUE
  
  if(OUT) { fid <- file(output.file, open="w")
            write(headr ,fid) }
  
  res <- matrix(fac, nrow = length(et), ncol = length(xs))
  
  if(OUT) { write.table( format(res),  fid, row.names=F, col.names=F, quote=F)
            print(paste("Generated", output.file)) 
            close(fid)}
  
  return(invisible(res))
}


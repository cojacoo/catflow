write.surface.pob <-
function(output.file="surface.pob", 
         xs = xsi, 
         lu = 33, precid = 1, climid = 1,   # landuse, precip ID's    , climate
         windid = rep(1,4),           # wind direction factors
         headr
         )
         {

if(missing(headr)) {headr <- paste("3  ", length(windid), "  0\n", 
                    "# Schlag-Id Clima-Id Niederschlag-Id Windrichtungsfaktoren",sep="")}

 if(length(lu) != length(xs)) {
    if(length(lu) == 1) lu <- rep(lu, length(xs))  else 
                              stop("Length mismatch: lu and xsi") }
    
    if(length(precid) != length(xs)) {
    if(length(precid) == 1) precid <- rep(precid, length(xs))  else 
                              stop("Length mismatch: precid and xsi") }
  
  if(length(climid) != length(xs)) {
    if(length(climid) == 1) climid <- rep(climid, length(xs))  else 
                              stop("Length mismatch: climid and xsi") }

 if(is.matrix(windid)) { stopifnot(nrow(windid)==length(xs))
   } else { 
      if(is.vector(windid)) windid <- matrix(windid, 
                                              nrow=length(xs), 
                                              ncol=length(windid),
                                              byrow=T)
      }
         
  surface.row <- character()
    
  for(i in seq_along(lu)) {
   surface.row <- rbind(surface.row, 
                        paste(c(lu[i], precid[i], climid[i], 
                                format(windid[i,], nsmall=1) )) ) }       
      
   fid <- file(output.file, open="w")
    write(headr ,fid)
    write.table( matrix(surface.row, length(lu), length( surface.row[1,]), byrow=F), fid, 
                 row.names=F, col.names=F, quote=F)  
   close(fid)
   
   print(paste("Generated surface attribute file '", output.file, "'.",sep="") ) 
   
   return(invisible())     }
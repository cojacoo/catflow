assign.mac.soil <-
function( output.file = "soil_horizons.bod",
          macgrid,                           # grid with macropores,
          eta = NULL,                        # vertical discretization
          xsi = NULL,                        # lateral discretization
          thresh=1,                          # threshold value soil/macro;
          soil.matrix=1,                     #  ID soil
          soil.macro=2,                      #  ID macros
          numh=1)                            # hillslope ID
  { 
  if(missing(macgrid)) {  macgrid <- matrix(1, length(eta), length(xsi))
                            replacing <- FALSE } else replacing <- TRUE
   
   headr= paste("BODEN",  nrow(macgrid), ncol(macgrid), numh)
             
   ## make grid with soil ID of matrix
    erg  <-  matrix(soil.matrix, nrow(macgrid), ncol(macgrid) )
   
   
   ## replace soil ID at macropores with macropore ID
   if(replacing)  erg[macgrid > thresh] <- soil.macro

    fid <- file(output.file, open="w")
     write(headr ,fid)
     write.table(erg,  fid, row.names=F, col.names=F)
    close(fid)
  
  print(paste("Generated", output.file)) 
  return(invisible())
}


discretize.pipe <-
function(sim, steph = 1, stepv = 1, maxdists, dimfaks, 
          top = 1:3, reg = TRUE, plottin = TRUE){

# make xsi vector/ lateral discretization
# keep fine resolution around vertical macropores 
# rest with maximum gap size of 'max.dist' columns (defaults to 2.5 % of dimension) 

# make eta vector/ horizontal discretization
# fine resolution around pipe
# rest with maximum gap size of 'max.dist' rows (defaults to 5 % of dimension) 
      
# beginning + end of pipe
 pip <- c( which.max(sim[[2]] > 0), length(sim[[2]]) - 1 )      # sim[[2]: rowmac
 dumgrd <- sim[[1]]*0
  dumgrd[, pip] <- 2

 positions <- unique(sim[[2]])


if(missing(maxdists)
) {                
    if(missing(dimfaks) ) { # if both are missing, use defaults
                          xsi.r <- discretize.xsi(dumgrd, steps = steph, reg = reg)
                          eta.r <- discretize.eta(positions, steps = stepv, 
                                                  top = top, relfak = sim[[1]], reg = reg)

      } else {   # missing maxdists: use dimfaks, eventually duplicating single entry
                 if(length(dimfaks) < 2) dimfaks <- rep(dimfaks[1],2)           
                 xsi.r <- discretize.xsi(dumgrd, steps = steph, dimfak = dimfaks[1], reg = reg)
                 eta.r <- discretize.eta(positions, steps = stepv, dimfak = dimfaks[2],
                                         top = top, relfak = sim[[1]], reg = reg)
             }
    
} else {      # use maxdists, eventually duplicating single entry
               if(length(maxdists) < 2) maxdists <- rep(maxdists[1],2)                    
               xsi.r <- discretize.xsi(dumgrd, steps = steph, max.dist = maxdists[1], reg = reg)
               eta.r <- discretize.eta(positions, steps = stepv, max.dist = maxdists[2], 
                                        top = top, relfak = sim[[1]], reg = reg)
        }
 # # #
 
  if( plottin ){
      plot(0:1, 0:1, t="n", ann = FALSE)
      abline(v = xsi.r, col = 8)
      image(t(sim[[1]]>1)[,nrow(sim[[1]]):1], col=0:1, add = TRUE)
       abline(h = c(0,1) )
       abline(h= eta.r, col = 3)
      }
      
return(list(xsi = xsi.r, eta = eta.r))
}


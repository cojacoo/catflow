discretize.rect <-
function(sim, steph = 1, stepv = 1, maxdists, dimfaks, 
          top = 1:3, reg = TRUE, plottin = TRUE){
  
 # make xsi vector/ lateral discretization
  # keep fine resolution around vertical macropores 
  # rest with maximum gap size of 'max.dist' columns (defaults to 2.5 % of dimension) 
  # make eta vector/ horizontal discretization
  # fine resolution around horizontal structures and endings of vert. macropores
  # rest with maximum gap size of 'max.dist' rows (defaults to 5 % of dimension) 

    # sim ## [[1]] simulated network
            #  [[2]] lmac: length and deepest position of vertical structures
            #  [[3]] rowmac: rownumbers of horizontal structures  
    # maxdists: horizontal and vertical maximum seperation [no. columns]
    # dimfaks: percentage of dimension (horiz/ vert)

relfak <- sim[[1]]

# make dummygrid: matrix relfak with filled columns where vertical structures are
dumgrd <- t(apply(sim[[1]],1,function(x) x* sim[[2]][2,] ))

positions <- sort(unique(c(sim[[3]],sim[[2]][2,]) ))      # rows horiz/ end vert.
        
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

 #Scaling relfak into new grid
   yy <- round((dim(relfak)[1]-1)*eta.r,1)+1        # eta starts at last row
    yy <- sort(abs(yy-nrow(relfak)-1))
   xx  <- round((dim(relfak)[2]-1)*xsi.r,1)+1
    relfak <- sim[[1]][yy,xx]
 
    if(plottin){ 
        plot(0:1,0:1,t = "n", ann = F)
        abline(v = xsi.r, col = 8)
        image(t(sim[[1]]>1)[,nrow(sim[[1]]):1], col = 0:1, add = TRUE)
         abline(h = c(0,1) , lwd = 2) ;abline(v = c(0,1) , lwd = 2)
         abline(h =  eta.r, col = 3)
     }

return(list(xsi = xsi.r, eta = eta.r, macgrid = relfak))
}

